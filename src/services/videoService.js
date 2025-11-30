/**
 * Video Service - handles video compression and processing
 * Uses fluent-ffmpeg for video manipulation
 * Requires ffmpeg binary to be installed on the system
 */

const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const fs = require('fs').promises;
const storageService = require('./storageService');
const { VIDEO_PRESETS } = require('../utils/constants');
const AppError = require('../utils/AppError');

// Configure ffmpeg path if provided via environment
if (process.env.FFMPEG_PATH) {
  ffmpeg.setFfmpegPath(process.env.FFMPEG_PATH);
}

class VideoService {
  /**
   * Get video metadata
   * @param {string} inputPath - Path to video file
   * @returns {Promise<Object>}
   */
  async getMetadata(inputPath) {
    return new Promise((resolve, reject) => {
      ffmpeg.ffprobe(inputPath, (err, metadata) => {
        if (err) {
          reject(AppError.internal(`Failed to get video metadata: ${err.message}`));
          return;
        }

        const videoStream = metadata.streams.find((s) => s.codec_type === 'video');
        const audioStream = metadata.streams.find((s) => s.codec_type === 'audio');

        resolve({
          duration: metadata.format.duration,
          size: metadata.format.size,
          bitrate: metadata.format.bit_rate,
          format: metadata.format.format_name,
          video: videoStream
            ? {
                codec: videoStream.codec_name,
                width: videoStream.width,
                height: videoStream.height,
                fps: eval(videoStream.r_frame_rate) || 30,
                bitrate: videoStream.bit_rate,
              }
            : null,
          audio: audioStream
            ? {
                codec: audioStream.codec_name,
                channels: audioStream.channels,
                sampleRate: audioStream.sample_rate,
                bitrate: audioStream.bit_rate,
              }
            : null,
        });
      });
    });
  }

  /**
   * Compress video with preset
   * @param {string} inputPath - Path to source video
   * @param {Object} options - Compression options
   * @returns {Promise<{path: string, originalSize: number, compressedSize: number}>}
   */
  async compress(inputPath, options = {}) {
    const { preset = 'medium', resolution, customBitrate } = options;

    // Get preset configuration
    const presetConfig = this.getPresetConfig(preset, resolution);
    const outputPath = storageService.getTempPath('.mp4');

    // Get original file size
    const originalStats = await fs.stat(inputPath);

    return new Promise((resolve, reject) => {
      let command = ffmpeg(inputPath)
        .outputOptions([
          '-c:v libx264', // H.264 codec
          '-preset medium', // Encoding speed preset
          '-crf 23', // Constant Rate Factor for quality
          `-b:v ${customBitrate || presetConfig.videoBitrate}`,
          '-c:a aac',
          `-b:a ${presetConfig.audioBitrate}`,
          '-movflags +faststart', // Enable fast start for web playback
        ])
        .output(outputPath);

      // Apply resolution scaling if specified
      if (presetConfig.width && presetConfig.height) {
        command = command.size(`${presetConfig.width}x${presetConfig.height}`);
      }

      command
        .on('start', (cmdline) => {
          console.log('FFmpeg started:', cmdline);
        })
        .on('progress', (progress) => {
          // Progress tracking (can be used for job status updates)
          if (progress.percent) {
            console.log(`Processing: ${Math.round(progress.percent)}%`);
          }
        })
        .on('end', async () => {
          try {
            const compressedStats = await fs.stat(outputPath);
            resolve({
              path: outputPath,
              originalSize: originalStats.size,
              compressedSize: compressedStats.size,
              reduction: Math.round((1 - compressedStats.size / originalStats.size) * 100),
              preset: presetConfig.name,
              resolution: presetConfig.resolution,
            });
          } catch (err) {
            reject(AppError.internal(`Failed to read compressed file: ${err.message}`));
          }
        })
        .on('error', (err) => {
          // Clean up partial output if exists
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Video compression failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Compress video to specific resolution
   * @param {string} inputPath - Path to source video
   * @param {string} targetResolution - Target resolution (480p, 720p, 1080p)
   * @returns {Promise<Object>}
   */
  async compressToResolution(inputPath, targetResolution) {
    const resolutionMap = {
      '480p': { width: 854, height: 480, bitrate: '1000k' },
      '720p': { width: 1280, height: 720, bitrate: '2500k' },
      '1080p': { width: 1920, height: 1080, bitrate: '5000k' },
    };

    const config = resolutionMap[targetResolution];
    if (!config) {
      throw AppError.badRequest(`Invalid resolution: ${targetResolution}`);
    }

    const outputPath = storageService.getTempPath('.mp4');
    const originalStats = await fs.stat(inputPath);

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .outputOptions([
          '-c:v libx264',
          '-preset medium',
          '-crf 23',
          `-b:v ${config.bitrate}`,
          '-c:a aac',
          '-b:a 128k',
          '-movflags +faststart',
        ])
        .size(`${config.width}x${config.height}`)
        .output(outputPath)
        .on('end', async () => {
          try {
            const compressedStats = await fs.stat(outputPath);
            resolve({
              path: outputPath,
              originalSize: originalStats.size,
              compressedSize: compressedStats.size,
              reduction: Math.round((1 - compressedStats.size / originalStats.size) * 100),
              resolution: targetResolution,
            });
          } catch (err) {
            reject(AppError.internal(`Failed to read compressed file: ${err.message}`));
          }
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Video compression failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Extract audio from video
   * @param {string} inputPath - Path to video
   * @param {Object} options - Extraction options
   * @returns {Promise<{path: string}>}
   */
  async extractAudio(inputPath, options = {}) {
    const { format = 'mp3', bitrate = '192k' } = options;
    const outputPath = storageService.getTempPath(`.${format}`);

    return new Promise((resolve, reject) => {
      let command = ffmpeg(inputPath).noVideo();

      if (format === 'mp3') {
        command = command.audioCodec('libmp3lame').audioBitrate(bitrate);
      } else if (format === 'aac') {
        command = command.audioCodec('aac').audioBitrate(bitrate);
      } else if (format === 'wav') {
        command = command.audioCodec('pcm_s16le');
      }

      command
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath, format });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Audio extraction failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Extract thumbnail from video
   * @param {string} inputPath - Path to video
   * @param {Object} options - Thumbnail options
   * @returns {Promise<{path: string}>}
   */
  async extractThumbnail(inputPath, options = {}) {
    const { timestamp = '00:00:01', width = 320, height = 240 } = options;
    const outputPath = storageService.getTempPath('.jpg');

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .seekInput(timestamp)
        .frames(1)
        .size(`${width}x${height}`)
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Thumbnail extraction failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Trim video
   * @param {string} inputPath - Path to video
   * @param {string} startTime - Start time (HH:MM:SS or seconds)
   * @param {string} endTime - End time (HH:MM:SS or seconds)
   * @returns {Promise<{path: string}>}
   */
  async trim(inputPath, startTime, endTime) {
    const outputPath = storageService.getTempPath('.mp4');

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .setStartTime(startTime)
        .setDuration(this.calculateDuration(startTime, endTime))
        .outputOptions(['-c copy']) // Copy without re-encoding for speed
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Video trim failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Convert video format
   * @param {string} inputPath - Path to video
   * @param {string} targetFormat - Target format (mp4, webm, avi, etc.)
   * @returns {Promise<{path: string}>}
   */
  async convertFormat(inputPath, targetFormat, options = {}) {
    const { quality = 'medium' } = options;
    const outputPath = storageService.getTempPath(`.${targetFormat}`);

    const formatConfigs = {
      mp4: {
        videoCodec: 'libx264',
        audioCodec: 'aac',
        outputOptions: ['-movflags +faststart'],
      },
      webm: {
        videoCodec: 'libvpx-vp9',
        audioCodec: 'libopus',
        outputOptions: ['-b:v 1M'],
      },
      avi: {
        videoCodec: 'mpeg4',
        audioCodec: 'mp3',
        outputOptions: [],
      },
      mkv: {
        videoCodec: 'libx264',
        audioCodec: 'aac',
        outputOptions: [],
      },
    };

    const config = formatConfigs[targetFormat];
    if (!config) {
      throw AppError.badRequest(`Unsupported target format: ${targetFormat}`);
    }

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .videoCodec(config.videoCodec)
        .audioCodec(config.audioCodec)
        .outputOptions(config.outputOptions)
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath, format: targetFormat });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Video conversion failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Rotate video
   * @param {string} inputPath - Path to video
   * @param {number} degrees - Rotation degrees (90, 180, 270)
   * @returns {Promise<{path: string}>}
   */
  async rotate(inputPath, degrees) {
    const outputPath = storageService.getTempPath('.mp4');

    const transposeMap = {
      90: 'transpose=1', // 90 clockwise
      180: 'transpose=2,transpose=2', // 180
      270: 'transpose=2', // 90 counter-clockwise
    };

    const transpose = transposeMap[degrees];
    if (!transpose) {
      throw AppError.badRequest('Rotation must be 90, 180, or 270 degrees');
    }

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .videoFilters(transpose)
        .outputOptions(['-c:a copy'])
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Video rotation failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Add watermark to video
   * @param {string} inputPath - Path to video
   * @param {string} watermarkPath - Path to watermark image
   * @param {Object} options - Watermark options
   * @returns {Promise<{path: string}>}
   */
  async addWatermark(inputPath, watermarkPath, options = {}) {
    const { position = 'bottomright', opacity = 0.5, scale = 0.2 } = options;
    const outputPath = storageService.getTempPath('.mp4');

    // Position mappings
    const positionMap = {
      topleft: '10:10',
      topright: 'main_w-overlay_w-10:10',
      bottomleft: '10:main_h-overlay_h-10',
      bottomright: 'main_w-overlay_w-10:main_h-overlay_h-10',
      center: '(main_w-overlay_w)/2:(main_h-overlay_h)/2',
    };

    const pos = positionMap[position] || positionMap.bottomright;

    return new Promise((resolve, reject) => {
      ffmpeg(inputPath)
        .input(watermarkPath)
        .complexFilter([
          `[1:v]scale=iw*${scale}:-1,format=rgba,colorchannelmixer=aa=${opacity}[wm]`,
          `[0:v][wm]overlay=${pos}[out]`,
        ])
        .outputOptions(['-map [out]', '-map 0:a?', '-c:a copy'])
        .output(outputPath)
        .on('end', () => {
          resolve({ path: outputPath });
        })
        .on('error', (err) => {
          fs.unlink(outputPath).catch(() => {});
          reject(AppError.internal(`Watermark addition failed: ${err.message}`));
        })
        .run();
    });
  }

  /**
   * Get preset configuration
   * @param {string} preset - Preset name
   * @param {string} resolution - Optional resolution override
   * @returns {Object}
   */
  getPresetConfig(preset, resolution) {
    const presets = {
      low: VIDEO_PRESETS.LOW,
      medium: VIDEO_PRESETS.MEDIUM,
      high: VIDEO_PRESETS.HIGH,
    };

    const config = presets[preset.toLowerCase()] || presets.medium;

    // Override with resolution if specified
    if (resolution) {
      const resolutions = {
        '480p': { width: 854, height: 480 },
        '720p': { width: 1280, height: 720 },
        '1080p': { width: 1920, height: 1080 },
      };
      const res = resolutions[resolution];
      if (res) {
        return { ...config, ...res, resolution };
      }
    }

    return config;
  }

  /**
   * Calculate duration from start and end time
   * @param {string} startTime - Start time
   * @param {string} endTime - End time
   * @returns {number} Duration in seconds
   */
  calculateDuration(startTime, endTime) {
    const parseTime = (time) => {
      if (typeof time === 'number') return time;
      const parts = time.split(':').map(Number);
      if (parts.length === 3) {
        return parts[0] * 3600 + parts[1] * 60 + parts[2];
      } else if (parts.length === 2) {
        return parts[0] * 60 + parts[1];
      }
      return parseFloat(time);
    };

    return parseTime(endTime) - parseTime(startTime);
  }

  /**
   * Check if ffmpeg is available
   * @returns {Promise<boolean>}
   */
  async isAvailable() {
    return new Promise((resolve) => {
      ffmpeg.getAvailableFormats((err, formats) => {
        resolve(!err && formats);
      });
    });
  }
}

module.exports = new VideoService();
