'use client';

import { useState } from 'react';

export default function AdminDashboard({ session, initialHalls, initialCourses }) {
  const [halls, setHalls] = useState(initialHalls);
  const [courses, setCourses] = useState(initialCourses);
  const [activeTab, setActiveTab] = useState('halls');
  
  // New Hall state
  const [hallName, setHallName] = useState('');
  const [hallCapacity, setHallCapacity] = useState('');
  const [hallFeatures, setHallFeatures] = useState('');
  const [hallBlock, setHallBlock] = useState('');
  
  // New Course state
  const [courseCode, setCourseCode] = useState('');
  const [courseName, setCourseName] = useState('');
  const [courseEnrolled, setCourseEnrolled] = useState('');
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const [editingHallId, setEditingHallId] = useState(null);
  const [editCapacity, setEditCapacity] = useState('');

  const handleUpdateCapacity = async (hallId) => {
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: hallId,
          capacity: parseInt(editCapacity)
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      
      setHalls(halls.map(h => h.id === hallId ? { ...h, capacity: data.capacity } : h));
      setSuccess('Capacity updated successfully!');
      setEditingHallId(null);
    } catch (err) {
      setError(err.message || 'Failed to update capacity');
    } finally {
      setLoading(false);
    }
  };

  const handleAddHall = async (e) => {
    e.preventDefault();
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/halls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: hallName,
          capacity: parseInt(hallCapacity),
          features: hallFeatures,
          building_block: hallBlock
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setHalls([...halls, data]);
      setSuccess('Hall added successfully!');
      setHallName(''); setHallCapacity(''); setHallFeatures(''); setHallBlock('');
    } catch (err) {
      setError(err.message || 'Failed to add hall');
    } finally {
      setLoading(false);
    }
  };

  const handleAddCourse = async (e) => {
    e.preventDefault();
    setLoading(true); setError(''); setSuccess('');
    try {
      const res = await fetch('/api/admin/courses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          code: courseCode,
          name: courseName,
          enrolled_count: parseInt(courseEnrolled),
          lecturer_id: session.id // Assign to admin for prototype to save time
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setCourses([...courses, data]);
      setSuccess('Course added successfully!');
      setCourseCode(''); setCourseName(''); setCourseEnrolled('');
    } catch (err) {
      setError(err.message || 'Failed to add course');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h2 style={{ fontSize: '2.25rem', fontWeight: '800', color: 'var(--primary-blue)', letterSpacing: '-0.025em' }}>Admin Dashboard</h2>
      </div>

      <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', borderBottom: '2px solid var(--border-color)', paddingBottom: '1rem' }}>
        <button 
          onClick={() => { setActiveTab('halls'); setError(''); setSuccess(''); }} 
          style={{ padding: '0.75rem 1.5rem', fontWeight: '700', borderRadius: '8px', cursor: 'pointer', border: 'none', background: activeTab === 'halls' ? 'rgba(30, 58, 138, 0.1)' : 'transparent', color: activeTab === 'halls' ? 'var(--primary-blue)' : 'var(--text-secondary)', transition: 'all 0.2s' }}
        >
          Manage Spaces
        </button>
        <button 
          onClick={() => { setActiveTab('courses'); setError(''); setSuccess(''); }} 
          style={{ padding: '0.75rem 1.5rem', fontWeight: '700', borderRadius: '8px', cursor: 'pointer', border: 'none', background: activeTab === 'courses' ? 'rgba(30, 58, 138, 0.1)' : 'transparent', color: activeTab === 'courses' ? 'var(--primary-blue)' : 'var(--text-secondary)', transition: 'all 0.2s' }}
        >
          Manage Courses
        </button>
      </div>

      {error && <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>{error}</div>}
      {success && <div style={{ backgroundColor: '#d1fae5', color: '#065f46', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontWeight: '600' }}>✓ {success}</div>}

      {activeTab === 'halls' ? (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Add Hall Form */}
          <div className="card" style={{ flex: 1, minWidth: '300px', position: 'sticky', top: '2rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.01em' }}>Add New Space</h3>
            <form onSubmit={handleAddHall} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Space Name</label>
                <input type="text" required value={hallName} onChange={e => setHallName(e.target.value)} className="input-field" placeholder="e.g. Auditorium C" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Capacity</label>
                <input type="number" required value={hallCapacity} onChange={e => setHallCapacity(e.target.value)} className="input-field" placeholder="e.g. 200" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Features (comma separated)</label>
                <input type="text" required value={hallFeatures} onChange={e => setHallFeatures(e.target.value)} className="input-field" placeholder="projector, whiteboard, AC" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Building Block</label>
                <input type="text" required value={hallBlock} onChange={e => setHallBlock(e.target.value)} className="input-field" placeholder="Main Block" />
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ marginTop: '0.5rem', padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Space'}
              </button>
            </form>
          </div>

          {/* List of Halls */}
          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Spaces</h3>
            {halls.map(hall => (
              <div key={hall.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.25rem' }}>{hall.name}</h4>
                  <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>{hall.building_block} • {hall.features.split(',').join(', ')}</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  {editingHallId === hall.id ? (
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <input 
                        type="number" 
                        value={editCapacity} 
                        onChange={(e) => setEditCapacity(e.target.value)} 
                        style={{ width: '80px', padding: '0.4rem', borderRadius: '4px', border: '1px solid var(--border-color)', background: 'var(--surface-color)', color: 'var(--text-primary)' }}
                        autoFocus
                      />
                      <button onClick={() => handleUpdateCapacity(hall.id)} style={{ background: 'var(--primary-blue)', color: 'white', border: 'none', padding: '0.4rem 0.8rem', borderRadius: '4px', cursor: 'pointer' }}>Save</button>
                      <button onClick={() => setEditingHallId(null)} style={{ background: 'transparent', color: 'var(--text-muted)', border: 'none', cursor: 'pointer' }}>Cancel</button>
                    </div>
                  ) : (
                    <>
                      <span className="badge badge-orange" style={{ padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{hall.capacity} seats</span>
                      <button 
                        onClick={() => { setEditingHallId(hall.id); setEditCapacity(hall.capacity); }} 
                        style={{ background: 'transparent', border: '1px solid var(--border-color)', borderRadius: '4px', padding: '0.3rem 0.6rem', cursor: 'pointer', color: 'var(--text-secondary)' }}
                        title="Edit Capacity"
                      >
                        ✏️
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', gap: '2rem', alignItems: 'flex-start', flexWrap: 'wrap' }}>
          {/* Add Course Form */}
          <div className="card" style={{ flex: 1, minWidth: '300px', position: 'sticky', top: '2rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '1.5rem', color: 'var(--primary-blue)', letterSpacing: '-0.01em' }}>Add New Course</h3>
            <form onSubmit={handleAddCourse} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Course Code</label>
                <input type="text" required value={courseCode} onChange={e => setCourseCode(e.target.value)} className="input-field" placeholder="e.g. CS202" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Course Name</label>
                <input type="text" required value={courseName} onChange={e => setCourseName(e.target.value)} className="input-field" placeholder="e.g. Data Structures" />
              </div>
              <div>
                <label style={{ display: 'block', fontWeight: '600', marginBottom: '0.5rem', color: 'var(--text-primary)' }}>Enrolled Students</label>
                <input type="number" required value={courseEnrolled} onChange={e => setCourseEnrolled(e.target.value)} className="input-field" placeholder="e.g. 150" />
              </div>
              <button type="submit" disabled={loading} className="btn-primary" style={{ marginTop: '0.5rem', padding: '1rem', fontSize: '1.05rem' }}>
                {loading ? 'Adding...' : 'Save Course'}
              </button>
            </form>
          </div>

          {/* List of Courses */}
          <div style={{ flex: 2, minWidth: '350px', display: 'grid', gap: '1rem' }}>
            <h3 style={{ fontSize: '1.5rem', fontWeight: '800', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Existing Courses</h3>
            {courses.map(course => (
              <div key={course.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1.25rem' }}>
                <div>
                  <h4 style={{ fontSize: '1.25rem', fontWeight: '700', marginBottom: '0.25rem' }}>{course.code} - {course.name}</h4>
                  {course.lecturer && <p style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Lecturer: {course.lecturer.name}</p>}
                </div>
                <span className="badge" style={{ backgroundColor: 'var(--text-primary)', padding: '0.4rem 0.8rem', fontSize: '0.85rem' }}>{course.enrolled_count} students</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
