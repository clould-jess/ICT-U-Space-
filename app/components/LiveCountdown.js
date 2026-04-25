'use client';
import { useState, useEffect } from 'react';

export default function LiveCountdown({ timetable, reservations }) {
  const [statusText, setStatusText] = useState('Loading schedule...');
  const [progress, setProgress] = useState(0);
  const [isActiveClass, setIsActiveClass] = useState(false);

  useEffect(() => {
    const updateCountdown = () => {
      const now = new Date();
      const currentDay = now.toLocaleDateString('en-US', { weekday: 'long' });
      const currentHours = now.getHours().toString().padStart(2, '0');
      const currentMinutes = now.getMinutes().toString().padStart(2, '0');
      const currentTimeStr = `${currentHours}:${currentMinutes}`;
      const offset = now.getTimezoneOffset();
      const todayDateStr = new Date(now.getTime() - (offset*60*1000)).toISOString().split('T')[0];

      // Combine timetable and reservations
      const todayEvents = [
        ...timetable.filter(t => t.day_of_week === currentDay).map(t => ({ ...t, title: t.course.name, type: 'Class' })),
        ...reservations.filter(r => r.date === todayDateStr && r.status === 'CONFIRMED').map(r => ({ ...r, title: r.course.name, type: 'Ad-hoc' }))
      ].sort((a, b) => a.start_time.localeCompare(b.start_time));

      if (todayEvents.length === 0) {
        setStatusText("No classes today! 🎉");
        setProgress(100);
        setIsActiveClass(false);
        return;
      }

      let activeEvent = null;
      let nextEvent = null;

      for (const event of todayEvents) {
        if (currentTimeStr >= event.start_time && currentTimeStr < event.end_time) {
          activeEvent = event;
          break;
        }
        if (currentTimeStr < event.start_time) {
          nextEvent = event;
          break;
        }
      }

      if (activeEvent) {
        setIsActiveClass(true);
        const startParts = activeEvent.start_time.split(':').map(Number);
        const endParts = activeEvent.end_time.split(':').map(Number);
        
        const startSecs = startParts[0] * 3600 + startParts[1] * 60;
        const endSecs = endParts[0] * 3600 + endParts[1] * 60;
        const currentSecs = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
        
        const totalDuration = endSecs - startSecs;
        const elapsed = currentSecs - startSecs;
        const percent = Math.min(100, Math.max(0, (elapsed / totalDuration) * 100));
        
        const secsLeft = endSecs - currentSecs;
        const hrsLeft = Math.floor(secsLeft / 3600);
        const minLeft = Math.floor((secsLeft % 3600) / 60);
        const secLeft = secsLeft % 60;
        
        const timeString = hrsLeft > 0 
          ? `${hrsLeft}h ${minLeft}m ${secLeft}s`
          : `${minLeft}m ${secLeft}s`;
          
        setStatusText(`Currently in ${activeEvent.title} (${timeString} left)`);
        setProgress(percent);
      } else if (nextEvent) {
        setIsActiveClass(false);
        const startParts = nextEvent.start_time.split(':').map(Number);
        const startSecs = startParts[0] * 3600 + startParts[1] * 60;
        const currentSecs = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
        const secsUntil = startSecs - currentSecs;
        
        const hrs = Math.floor(secsUntil / 3600);
        const mins = Math.floor((secsUntil % 3600) / 60);
        const secs = secsUntil % 60;
        
        let timeStr = '';
        if (hrs > 0) timeStr += `${hrs}h `;
        if (mins > 0 || hrs > 0) timeStr += `${mins}m `;
        timeStr += `${secs}s`;
        
        setStatusText(`Next up: ${nextEvent.title} in ${timeStr}`);
        setProgress(0);
      } else {
        setIsActiveClass(false);
        setStatusText("All classes finished for today! 🎉");
        setProgress(100);
      }
    };

    updateCountdown();
    const interval = setInterval(updateCountdown, 1000); 
    return () => clearInterval(interval);
  }, [timetable, reservations]);

  return (
    <div style={{ background: 'var(--surface-color)', padding: '1.5rem', borderRadius: '12px', marginBottom: '2rem', border: '1px solid var(--border-color)', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
        <h3 style={{ fontSize: '1.1rem', fontWeight: 'bold', color: 'var(--primary-blue)', margin: 0 }}>Live Schedule Tracker</h3>
        {isActiveClass && <span style={{ fontSize: '0.8rem', backgroundColor: 'var(--error)', color: 'white', padding: '0.2rem 0.6rem', borderRadius: '10px', fontWeight: 'bold', animation: 'pulse 2s infinite' }}>LIVE</span>}
      </div>
      <p style={{ fontSize: '1.25rem', fontWeight: '800', marginBottom: '1rem', color: 'var(--text-primary)' }}>{statusText}</p>
      
      {isActiveClass && (
        <div style={{ width: '100%', height: '8px', backgroundColor: 'var(--bg-color)', borderRadius: '4px', overflow: 'hidden' }}>
          <div style={{ width: `${progress}%`, height: '100%', backgroundColor: 'var(--accent-orange)', transition: 'width 1s linear' }}></div>
        </div>
      )}
    </div>
  );
}
