require('dotenv').config();
const ImageKit = require('imagekit');

const hasImageKitConfig =
    Boolean(process.env.IMAGEKIT_PUBLIC_KEY) &&
    Boolean(process.env.IMAGEKIT_PRIVATE_KEY) &&
    Boolean(process.env.IMAGEKIT_URL_ENDPOINT);

const imagekit = hasImageKitConfig
    ? new ImageKit({
        publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
        privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
        urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT,
    })
    : {
        upload() {
            return Promise.reject(
                new Error('ImageKit is not configured on this deployment.')
            );
        },
    };

module.exports = imagekit;
// https://ik.imagekit.io/transglobe
