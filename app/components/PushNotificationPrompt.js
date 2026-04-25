'use client';
import { useState, useEffect } from 'react';

export default function PushNotificationPrompt() {
  const [isSupported, setIsSupported] = useState(false);
  const [isSubscribed, setIsSubscribed] = useState(false);

  useEffect(() => {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
      setIsSupported(true);
      
      navigator.serviceWorker.register('/sw.js').then(reg => {
        reg.pushManager.getSubscription().then(sub => {
          if (sub) setIsSubscribed(true);
        });
      });
    }
  }, []);

  const urlBase64ToUint8Array = (base64String) => {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  };

  const subscribeUser = async () => {
    try {
      const registration = await navigator.serviceWorker.ready;
      
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY)
      });

      // Send subscription to backend
      await fetch('/api/notifications/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription)
      });

      setIsSubscribed(true);
      alert('You are now subscribed to receive notifications!');
    } catch (err) {
      console.error('Failed to subscribe the user: ', err);
      alert('Failed to enable push notifications. Please check browser permissions.');
    }
  };

  if (!isSupported || isSubscribed) return null;

  return (
    <div style={{ backgroundColor: 'var(--primary-blue)', color: 'white', padding: '1rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderRadius: '12px', marginBottom: '2rem', boxShadow: '0 4px 12px rgba(30, 58, 138, 0.2)' }}>
      <div>
        <h4 style={{ fontWeight: '800', marginBottom: '0.25rem', fontSize: '1.1rem' }}>Enable Push Notifications</h4>
        <p style={{ fontSize: '0.9rem', opacity: 0.9 }}>Get instantly notified on your phone when a class is booked or changed.</p>
      </div>
      <button 
        onClick={subscribeUser}
        style={{ backgroundColor: 'var(--accent-orange)', color: 'white', border: 'none', padding: '0.75rem 1.5rem', borderRadius: '8px', fontWeight: 'bold', cursor: 'pointer', transition: 'background-color 0.2s', boxShadow: '0 2px 8px rgba(251, 146, 60, 0.4)' }}
      >
        Enable Push
      </button>
    </div>
  );
}
