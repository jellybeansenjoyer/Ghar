import { v2 as cloudinary } from 'cloudinary';
import { env } from '../config/env';

let configured = false;

function ensureConfigured(): boolean {
  if (configured) return true;
  if (!env.CLOUDINARY_CLOUD_NAME || !env.CLOUDINARY_API_KEY || !env.CLOUDINARY_API_SECRET) {
    console.warn('⚠️ Cloudinary not configured. Image uploads will be skipped.');
    return false;
  }
  cloudinary.config({
    cloud_name: env.CLOUDINARY_CLOUD_NAME,
    api_key: env.CLOUDINARY_API_KEY,
    api_secret: env.CLOUDINARY_API_SECRET,
  });
  configured = true;
  return true;
}

export async function uploadImage(
  fileBuffer: Buffer,
  folder: string = 'ghar/visitors'
): Promise<string | null> {
  if (!ensureConfigured()) {
    console.log('📷 [DEV] Image upload skipped (Cloudinary not configured)');
    return null;
  }

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: 'image',
        transformation: [
          { width: 500, height: 500, crop: 'limit' },
          { quality: 'auto', fetch_format: 'auto' },
        ],
      },
      (error, result) => {
        if (error) {
          console.error('Cloudinary upload error:', JSON.stringify(error, null, 2));
          reject(error);
        } else {
          resolve(result?.secure_url || null);
        }
      }
    );
    uploadStream.end(fileBuffer);
  });
}
