importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyC7SGsD3I7EOEKDh8VXchJGSYz6dnLqM4I',
    appId: '1:1072284227316:web:f7c08816b810cc00cd30a1',
    messagingSenderId: '1072284227316',
    projectId: 'mera-ubar',
    authDomain: 'mera-ubar.firebaseapp.com',
    storageBucket: 'mera-ubar.firebasestorage.app',
    measurementId: 'G-1BETFQFRZV',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
