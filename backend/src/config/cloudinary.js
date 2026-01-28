import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Upload image to Cloudinary
 * @param {string} imagePath - Local path or base64 data URI
 * @param {string} folder - Folder name in Cloudinary
 * @returns {Promise<object>} Cloudinary upload result
 */
export const uploadImage = async (imagePath, folder = 'lostlink') => {
  try {
    const result = await cloudinary.uploader.upload(imagePath, {
      folder,
      transformation: [
        { width: 1200, height: 1200, crop: 'limit' }, // Max size
        { quality: 'auto' }, // Auto quality
        { fetch_format: 'auto' }, // Auto format (webp when supported)
      ],
    });

    return {
      url: result.secure_url,
      publicId: result.public_id,
      width: result.width,
      height: result.height,
      format: result.format,
      size: result.bytes,
    };
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    throw new Error('Failed to upload image');
  }
};

/**
 * Upload image from buffer
 * @param {Buffer} buffer - Image buffer
 * @param {string} folder - Folder name
 * @returns {Promise<object>} Upload result
 */
export const uploadImageBuffer = (buffer, folder = 'lostlink') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        transformation: [
          { width: 1200, height: 1200, crop: 'limit' },
          { quality: 'auto' },
          { fetch_format: 'auto' },
        ],
      },
      (error, result) => {
        if (error) {
          reject(new Error('Failed to upload image'));
        } else {
          resolve({
            url: result.secure_url,
            publicId: result.public_id,
            width: result.width,
            height: result.height,
            format: result.format,
            size: result.bytes,
          });
        }
      }
    );

    uploadStream.end(buffer);
  });
};

/**
 * Delete image from Cloudinary
 * @param {string} publicId - Cloudinary public ID
 * @returns {Promise<boolean>}
 */
export const deleteImage = async (publicId) => {
  try {
    await cloudinary.uploader.destroy(publicId);
    return true;
  } catch (error) {
    console.error('Cloudinary delete error:', error);
    return false;
  }
};

/**
 * Generate thumbnail URL
 * @param {string} url - Original image URL
 * @param {number} width - Thumbnail width
 * @param {number} height - Thumbnail height
 * @returns {string} Thumbnail URL
 */
export const getThumbnailUrl = (url, width = 300, height = 300) => {
  // Transform Cloudinary URL to include thumbnail transformation
  if (url.includes('cloudinary.com')) {
    return url.replace('/upload/', `/upload/c_fill,w_${width},h_${height}/`);
  }
  return url;
};

export default cloudinary;
