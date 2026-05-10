<<<<<<< HEAD
import prisma from '../../../../../../lib/prisma';
import { cookies } from 'next/headers';

export async function PUT(request, { params }) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });

    const session = JSON.parse(sessionCookie.value);
    if (session.role !== 'ADMIN') return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { id } = await params;
    const { role } = await request.json();

    if (!role || !['STUDENT', 'PREFECT', 'LECTURER', 'ADMIN'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Invalid role' }), { status: 400 });
=======
import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function PUT(request, { params }) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    }

    const session = JSON.parse(sessionCookie.value);
    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden. Admin access required.' }), { status: 403 });
    }

    const id = params.id;
    const { role } = await request.json();

    if (!role || !['STUDENT', 'PREFECT', 'LECTURER', 'ADMIN'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Invalid role provided' }), { status: 400 });
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: { role },
<<<<<<< HEAD
      select: { id: true, name: true, email: true, role: true }
=======
      select: { id: true, name: true, email: true, role: true } // Don't return password
>>>>>>> 1229ad69d61cc025bf7943a328efa21b2faae813
    });

    return new Response(JSON.stringify({ success: true, user: updatedUser }), { status: 200 });
  } catch (error) {
    console.error('Update role error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
}
