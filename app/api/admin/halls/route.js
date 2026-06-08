import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

async function requireAdmin() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) return null;
  const session = JSON.parse(sessionCookie.value);
  return session.role === 'ADMIN' ? session : null;
}

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const { name, capacity, features, building_block } = await request.json();

    const hall = await prisma.hall.create({
      data: { name, capacity, features, building_block }
    });

    return new Response(JSON.stringify(hall), { status: 201, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to create hall' }), { status: 500, headers: corsHeaders });
  }
}

export async function DELETE(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return new Response(JSON.stringify({ error: 'Hall id required' }), { status: 400, headers: corsHeaders });

    await prisma.hall.delete({ where: { id } });
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to delete hall' }), { status: 500, headers: corsHeaders });
  }
}

export async function PUT(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const { id, capacity } = await request.json();

    const hall = await prisma.hall.update({
      where: { id },
      data: { capacity: parseInt(capacity) }
    });

    return new Response(JSON.stringify(hall), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to update hall' }), { status: 500, headers: corsHeaders });
  }
}

export async function DELETE(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { id } = await request.json();
    await prisma.hall.delete({ where: { id } });
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to delete hall' }), { status: 500 });
  }
}
