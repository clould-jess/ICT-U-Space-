import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function PUT(request, { params }) {
  try {
    const session = await getSession(request);
    if (!session) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });
    }

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden. Admin access required.' }), { status: 403, headers: corsHeaders });
    }

    const { id } = await params;
    const { role } = await request.json();

    if (!role || !['STUDENT', 'PREFECT', 'LECTURER', 'ADMIN'].includes(role)) {
      return new Response(JSON.stringify({ error: 'Invalid role provided' }), { status: 400, headers: corsHeaders });
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: { role },
      select: { id: true, name: true, email: true, role: true }
    });

    return new Response(JSON.stringify({ success: true, user: updatedUser }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Update role error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
