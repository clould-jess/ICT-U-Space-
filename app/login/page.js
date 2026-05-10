'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (res.ok) {
        router.push('/');
        router.refresh();
      } else {
        const data = await res.json();
        setError(data.error || 'Login failed');
      }
    } catch {
      setError('An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', backgroundColor: 'transparent' }}>
      {/* Left side: branding */}
      <div style={{ flex: 1, background: 'color-mix(in srgb, var(--primary-blue) 40%, transparent)', backdropFilter: 'blur(16px)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'white', padding: '3rem', borderRight: '1px solid color-mix(in srgb, var(--border-color) 30%, transparent)' }}>
        <div style={{ width: '80px', height: '80px', borderRadius: '50%', background: 'var(--primary-blue)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '2.5rem', marginBottom: '2rem', boxShadow: '0 10px 25px rgba(0,0,0,0.2)' }}>
          S
        </div>
        <h1 style={{ fontSize: '3.5rem', fontWeight: '800', marginBottom: '1.5rem', textAlign: 'center', letterSpacing: '-0.025em' }}>ICT-U Space</h1>
        <p style={{ fontSize: '1.25rem', textAlign: 'center', maxWidth: '400px', opacity: 0.9, lineHeight: 1.6 }}>
          Intelligent classroom reservations and real-time schedule management.
        </p>
        <div style={{ marginTop: '3rem', display: 'flex', flexDirection: 'column', gap: '1rem', width: '100%', maxWidth: '320px' }}>
          {['Book rooms instantly', 'Real-time availability', 'Smart notifications', 'Multi-role access'].map(f => (
            <div key={f} style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', opacity: 0.9 }}>
              <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--accent-orange)', flexShrink: 0 }} />
              <span style={{ fontSize: '1rem' }}>{f}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Right side: Login form */}
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '2rem' }}>
        <div className="card" style={{ width: '100%', maxWidth: '450px', padding: '3.5rem 3rem' }}>
          <h2 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem', color: 'var(--primary-blue)' }}>Welcome Back</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: '2.5rem' }}>Sign in to manage your spaces and schedule</p>

          {error && (
            <div style={{ backgroundColor: '#fee2e2', color: '#b91c1c', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontSize: '0.875rem', fontWeight: '500', borderLeft: '4px solid #b91c1c' }}>
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <div>
              <label htmlFor="email" style={{ display: 'block', fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-primary)', marginBottom: '0.5rem' }}>Email Address</label>
              <input
                id="email"
                type="email"
                className="input-field"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                placeholder="you@ictuniversity.edu.cm"
              />
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                <label htmlFor="password" style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--text-primary)' }}>Password</label>
                <a href="#" style={{ color: 'var(--primary-blue)', textDecoration: 'none', fontWeight: '500', fontSize: '0.85rem' }}>Forgot password?</a>
              </div>
              <input
                id="password"
                type="password"
                className="input-field"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
              />
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="btn-primary"
              style={{ padding: '1rem', fontSize: '1.125rem', marginTop: '0.5rem' }}
            >
              {isLoading ? 'Signing in...' : 'Log In'}
            </button>

            <p style={{ textAlign: 'center', color: 'var(--text-secondary)', fontSize: '0.9rem' }}>
              No account yet?{' '}
              <Link href="/signup" style={{ color: 'var(--primary-blue)', fontWeight: '600', textDecoration: 'none' }}>
                Create one
              </Link>
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}
