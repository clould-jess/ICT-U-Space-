import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

// GET /api/courses/[id] — returns course detail including enrolled students (for lecturer to pick prefect)
export async function GET(request, { params }) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { id } = await params;
    const course = await prisma.course.findUnique({
      where: { id },
      include: {
        lecturer: { select: { id: true, name: true } },
        delegate: { select: { id: true, name: true } },
        students: { select: { id: true, name: true, matricule: true } },
      },
    });
    if (!course) return new Response(JSON.stringify({ error: 'Course not found' }), { status: 404, headers: corsHeaders });

    return new Response(JSON.stringify(course), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500, headers: corsHeaders });
  }
}

export async function PUT(request, { params }) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { id } = await params;
    const body = await request.json();
    const { lecturer_id, delegate_id } = body;

    const course = await prisma.course.findUnique({
      where: { id },
      include: { lecturer: { select: { id: true } } },
    });
    if (!course) return new Response(JSON.stringify({ error: 'Course not found' }), { status: 404, headers: corsHeaders });

    const isAdmin = session.role === 'ADMIN';
    const isLecturerOfThisCourse = course.lecturer_id === session.id;

    // --- LECTURER claiming a course ---
    if (lecturer_id !== undefined && !isAdmin) {
      // Lecturer can only set themselves
      if (session.role !== 'LECTURER' || lecturer_id !== session.id) {
        return new Response(JSON.stringify({ error: 'Lecturers can only claim courses for themselves.' }), { status: 403, headers: corsHeaders });
      }
      // Course must be unclaimed
      if (course.lecturer_id && course.lecturer_id !== session.id) {
        return new Response(JSON.stringify({ error: 'This course already has a lecturer.' }), { status: 409, headers: corsHeaders });
      }
      // No other course should already be claimed by this lecturer with the same code
      // (allow a lecturer to teach multiple different courses, just not duplicates)
    }

    // --- Assigning a delegate ---
    if (delegate_id !== undefined && !isAdmin && !isLecturerOfThisCourse) {
      return new Response(JSON.stringify({ error: 'Only the course lecturer or admin can assign a delegate.' }), { status: 403, headers: corsHeaders });
    }

    const updateData = {};
    if (lecturer_id !== undefined) updateData.lecturer_id = lecturer_id;
    if (delegate_id !== undefined) updateData.delegate_id = delegate_id;

    // Auto-upgrade delegate to PREFECT if they are a STUDENT
    if (delegate_id) {
      const delegateUser = await prisma.user.findUnique({ where: { id: delegate_id } });
      if (delegateUser && delegateUser.role === 'STUDENT') {
        await prisma.user.update({ where: { id: delegate_id }, data: { role: 'PREFECT' } });
      }
    }

    const updatedCourse = await prisma.course.update({ where: { id }, data: updateData });
    return new Response(JSON.stringify({ success: true, course: updatedCourse }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Course update error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500, headers: corsHeaders });
  }
}

// DELETE — lecturer unclaims their own course; admin can unclaim any
export async function DELETE(request, { params }) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { id } = await params;
    const course = await prisma.course.findUnique({ where: { id } });
    if (!course) return new Response(JSON.stringify({ error: 'Course not found' }), { status: 404, headers: corsHeaders });

    if (session.role !== 'ADMIN' && course.lecturer_id !== session.id) {
      return new Response(JSON.stringify({ error: 'You can only unclaim your own courses.' }), { status: 403, headers: corsHeaders });
    }

    await prisma.course.update({ where: { id }, data: { lecturer_id: null } });
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500, headers: corsHeaders });
  }
}
