'use client';
import { useState, useEffect } from 'react';
import { useTheme } from 'next-themes';

export default function SettingsModal({ session, onClose }) {
  const [activeTab, setActiveTab] = useState('profile');
  const [userData, setUserData] = useState(null);
  const [allCourses, setAllCourses] = useState([]);
  
  // Profile state
  const [level, setLevel] = useState('');
  const [semester, setSemester] = useState('');
  
  // Courses state
  const [enrolledIds, setEnrolledIds] = useState([]);

  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
    fetch('/api/user/settings')
      .then(res => res.json())
      .then(data => {
        setUserData(data.user);
        setAllCourses(data.allCourses);
        setLevel(data.user.academic_level || '');
        setSemester(data.user.semester || '');
        setEnrolledIds(data.user.enrolledIn.map(c => c.id));
      });
  }, []);

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    await fetch('/api/user/settings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ academic_level: level, semester })
    });
    alert('Profile saved!');
  };

  const handleToggleCourse = async (courseId) => {
    const newEnrolled = enrolledIds.includes(courseId) 
      ? enrolledIds.filter(id => id !== courseId)
      : [...enrolledIds, courseId];
    
    setEnrolledIds(newEnrolled);
    
    await fetch('/api/user/settings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ courseIds: newEnrolled })
    });
  };

  if (!mounted || !userData) return null;

  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
      <div className="card" style={{ width: '100%', maxWidth: '600px', maxHeight: '90vh', display: 'flex', flexDirection: 'column', padding: 0, overflow: 'hidden' }}>
        
        {/* Header */}
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border-color)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: '800', color: 'var(--primary-blue)' }}>Settings</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: '2rem', cursor: 'pointer', color: 'var(--text-muted)' }}>&times;</button>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', borderBottom: '1px solid var(--border-color)' }}>
          <button onClick={() => setActiveTab('profile')} style={{ flex: 1, padding: '1rem', fontWeight: 'bold', background: activeTab === 'profile' ? 'var(--bg-color)' : 'transparent', border: 'none', cursor: 'pointer', color: activeTab === 'profile' ? 'var(--primary-blue)' : 'var(--text-secondary)' }}>Profile</button>
          <button onClick={() => setActiveTab('courses')} style={{ flex: 1, padding: '1rem', fontWeight: 'bold', background: activeTab === 'courses' ? 'var(--bg-color)' : 'transparent', border: 'none', cursor: 'pointer', color: activeTab === 'courses' ? 'var(--primary-blue)' : 'var(--text-secondary)' }}>My Courses</button>
          <button onClick={() => setActiveTab('appearance')} style={{ flex: 1, padding: '1rem', fontWeight: 'bold', background: activeTab === 'appearance' ? 'var(--bg-color)' : 'transparent', border: 'none', cursor: 'pointer', color: activeTab === 'appearance' ? 'var(--primary-blue)' : 'var(--text-secondary)' }}>Appearance</button>
        </div>

        {/* Content */}
        <div style={{ padding: '2rem', overflowY: 'auto', flex: 1, backgroundColor: 'var(--bg-color)' }}>
          
          {activeTab === 'profile' && (
            <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Academic Level</label>
                <select value={level} onChange={e => setLevel(e.target.value)} className="input-field">
                  <option value="">Select Level</option>
                  <option value="Level 1">Level 1</option>
                  <option value="Level 2">Level 2</option>
                  <option value="Level 3">Level 3</option>
                  <option value="Level 4">Level 4</option>
                </select>
              </div>
              
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Semester</label>
                <select value={semester} onChange={e => setSemester(e.target.value)} className="input-field">
                  <option value="">Select Semester</option>
                  <option value="Fall26">Fall 26</option>
                  <option value="Spring26">Spring 26</option>
                  <option value="Summer26">Summer 26</option>
                  <option value="Fall27">Fall 27</option>
                  <option value="Spring27">Spring 27</option>
                </select>
              </div>

              <button type="submit" className="btn-primary" style={{ marginTop: '1rem', padding: '1rem', fontSize: '1.05rem' }}>Save Profile</button>
            </form>
          )}

          {activeTab === 'courses' && (
            <div>
              <p style={{ marginBottom: '1.5rem', color: 'var(--text-secondary)' }}>Select the courses you are currently taking.</p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {allCourses.map(course => {
                  const isEnrolled = enrolledIds.includes(course.id);
                  return (
                    <div key={course.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem', border: '1px solid var(--border-color)', borderRadius: '8px', backgroundColor: 'var(--surface-color)' }}>
                      <div>
                        <h4 style={{ fontWeight: 'bold', color: 'var(--text-primary)' }}>{course.code} - {course.name}</h4>
                        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>{course.lecturer?.name}</p>
                      </div>
                      <button 
                        onClick={() => handleToggleCourse(course.id)}
                        style={{ padding: '0.5rem 1.25rem', borderRadius: '6px', fontWeight: 'bold', border: 'none', cursor: 'pointer', backgroundColor: isEnrolled ? 'var(--error)' : 'var(--primary-blue)', color: 'white', transition: 'opacity 0.2s' }}
                      >
                        {isEnrolled ? 'Drop' : 'Enroll'}
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {activeTab === 'appearance' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <p style={{ marginBottom: '1rem', color: 'var(--text-secondary)' }}>Choose how the app looks for you.</p>
              
              <button 
                onClick={() => setTheme('light')} 
                style={{ padding: '1rem', borderRadius: '8px', border: theme === 'light' ? '2px solid var(--primary-blue)' : '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)', cursor: 'pointer', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>Light Theme</span>
                {theme === 'light' && <span style={{color: 'var(--primary-blue)'}}>✓</span>}
              </button>
              
              <button 
                onClick={() => setTheme('dark')} 
                style={{ padding: '1rem', borderRadius: '8px', border: theme === 'dark' ? '2px solid var(--primary-blue)' : '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)', cursor: 'pointer', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>Dark Theme</span>
                {theme === 'dark' && <span style={{color: 'var(--primary-blue)'}}>✓</span>}
              </button>

              <button 
                onClick={() => setTheme('hacker')} 
                style={{ padding: '1rem', borderRadius: '8px', border: theme === 'hacker' ? '2px solid var(--primary-blue)' : '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)', cursor: 'pointer', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>Hacker Theme 👨‍💻</span>
                {theme === 'hacker' && <span style={{color: 'var(--primary-blue)'}}>✓</span>}
              </button>
              
              <button 
                onClick={() => setTheme('sunset')} 
                style={{ padding: '1rem', borderRadius: '8px', border: theme === 'sunset' ? '2px solid var(--primary-blue)' : '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)', cursor: 'pointer', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>Sunset Theme 🌅</span>
                {theme === 'sunset' && <span style={{color: 'var(--primary-blue)'}}>✓</span>}
              </button>
              
              <button 
                onClick={() => setTheme('system')} 
                style={{ padding: '1rem', borderRadius: '8px', border: theme === 'system' ? '2px solid var(--primary-blue)' : '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)', cursor: 'pointer', fontWeight: 'bold', display: 'flex', justifyContent: 'space-between' }}
              >
                <span>System Default</span>
                {theme === 'system' && <span style={{color: 'var(--primary-blue)'}}>✓</span>}
              </button>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}
