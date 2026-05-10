'use client';
import { useState } from 'react';
import SettingsModal from './SettingsModal';

export default function ProfileAvatar({ session }) {
  const [isOpen, setIsOpen] = useState(false);
  
  const colors = [
    '#f44336', '#e91e63', '#9c27b0', '#673ab7', '#3f51b5', '#2196f3',
    '#03a9f4', '#00bcd4', '#009688', '#4caf50', '#8bc34a', '#cddc39',
    '#ffb300', '#ff9800', '#ff5722', '#795548', '#9e9e9e', '#607d8b',
    '#ef5350', '#ab47bc', '#5c6bc0', '#29b6f6', '#26a69a', '#d4e157',
    '#ffa726', '#8d6e63'
  ];
  
  const initial = session?.name ? session.name.charAt(0).toUpperCase() : 'U';
  
  // Calculate color index based on the ASCII value of the initial letter
  let colorIndex = (initial.charCodeAt(0) - 65) % colors.length;
  if (colorIndex < 0 || isNaN(colorIndex)) colorIndex = 0;
  
  const bgColor = colors[colorIndex];

  return (
    <>
      <button 
        onClick={() => setIsOpen(true)}
        style={{ 
          backgroundColor: bgColor, 
          border: 'none', 
          cursor: 'pointer', 
          padding: '0', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center',
          borderRadius: '50%',
          width: '42px',
          height: '42px',
          color: 'white',
          fontSize: '1.4rem',
          fontWeight: '600',
          transition: 'transform 0.2s ease',
          boxShadow: '0 2px 5px rgba(0,0,0,0.2)'
        }}
        title="Profile Settings"
        onMouseOver={e => e.currentTarget.style.transform = 'scale(1.05)'}
        onMouseOut={e => e.currentTarget.style.transform = 'scale(1)'}
      >
        {initial}
      </button>
      
      {isOpen && <SettingsModal session={session} onClose={() => { setIsOpen(false); window.location.reload(); }} />}
    </>
  );
}
