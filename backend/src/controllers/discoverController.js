const { query } = require('../config/database');

// Get all professionals for discover page
const getProfessionals = async (req, res) => {
  try {
    const { location, field, search, limit = 50, offset = 0 } = req.query;
    const userId = req.user.id;

    let sql = `
      SELECT 
        p.id,
        p.user_id,
        p.full_name,
        p.profession,
        p.location,
        p.field,
        p.avatar_url,
        p.bio,
        p.connections_count,
        COALESCE(
          json_agg(
            DISTINCT pt.tag
          ) FILTER (WHERE pt.tag IS NOT NULL),
          '[]'
        ) as tags,
        CASE 
          WHEN c.id IS NOT NULL THEN c.status
          ELSE NULL
        END as connection_status
      FROM professionals p
      LEFT JOIN professional_tags pt ON p.id = pt.professional_id
      LEFT JOIN connections c ON (
        (c.sender_id = $1 AND c.receiver_id = p.user_id) OR
        (c.receiver_id = $1 AND c.sender_id = p.user_id)
      )
      WHERE p.is_public = TRUE
      AND (p.user_id != $1 OR p.user_id IS NULL)
    `;
    
    const params = [userId];
    let paramCount = 2;

    if (location && location !== 'All') {
      sql += ` AND p.location = $${paramCount}`;
      params.push(location);
      paramCount++;
    }

    if (field && field !== 'All') {
      sql += ` AND p.field = $${paramCount}`;
      params.push(field);
      paramCount++;
    }

    if (search) {
      sql += ` AND (
        p.full_name ILIKE $${paramCount} OR
        p.profession ILIKE $${paramCount} OR
        p.bio ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
      paramCount++;
    }

    sql += `
      GROUP BY p.id, c.id
      ORDER BY p.connections_count DESC, p.created_at DESC
      LIMIT $${paramCount} OFFSET $${paramCount + 1}
    `;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(sql, params);

    // Get total count
    let countSql = `
      SELECT COUNT(DISTINCT p.id) as total 
      FROM professionals p 
      WHERE p.is_public = TRUE AND (p.user_id != $1 OR p.user_id IS NULL)
    `;
    const countParams = [userId];
    let countParamCount = 2;

    if (location && location !== 'All') {
      countSql += ` AND p.location = $${countParamCount}`;
      countParams.push(location);
      countParamCount++;
    }

    if (field && field !== 'All') {
      countSql += ` AND p.field = $${countParamCount}`;
      countParams.push(field);
      countParamCount++;
    }

    if (search) {
      countSql += ` AND (
        p.full_name ILIKE $${countParamCount} OR
        p.profession ILIKE $${countParamCount} OR
        p.bio ILIKE $${countParamCount}
      )`;
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countSql, countParams);

    res.json({
      success: true,
      data: result.rows.map(row => ({
        id: row.id,
        userId: row.user_id,
        name: row.full_name,
        profession: row.profession,
        location: row.location,
        field: row.field,
        avatar: row.avatar_url,
        bio: row.bio,
        connections: row.connections_count,
        tags: row.tags || [],
        connectionStatus: row.connection_status,
      })),
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
      },
    });
  } catch (error) {
    console.error('Get professionals error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch professionals',
      error: error.message,
    });
  }
};

// Send connection request
const sendConnectionRequest = async (req, res) => {
  try {
    const { receiverId, message } = req.body;
    const senderId = req.user.id;

    if (!receiverId) {
      return res.status(400).json({
        success: false,
        message: 'Receiver ID is required',
      });
    }

    if (receiverId === senderId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot send connection request to yourself',
      });
    }

    // Check if connection already exists
    const existingConnection = await query(
      `SELECT id, status FROM connections 
       WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1)`,
      [senderId, receiverId]
    );

    if (existingConnection.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Connection request already exists',
        status: existingConnection.rows[0].status,
      });
    }

    // Create connection request
    const result = await query(
      `INSERT INTO connections (sender_id, receiver_id, message, status) 
       VALUES ($1, $2, $3, 'pending') 
       RETURNING id, sender_id, receiver_id, status, message, created_at`,
      [senderId, receiverId, message || null]
    );

    // Create notification for receiver
    try {
      await query(
        `INSERT INTO notifications (user_id, type, title, message, data)
         VALUES ($1, 'connection_request', 'New Connection Request', $2, $3)`,
        [
          receiverId,
          'You have received a new connection request',
          JSON.stringify({ connectionId: result.rows[0].id, senderId })
        ]
      );
    } catch (notifError) {
      console.error('Failed to create notification:', notifError);
      // Continue even if notification fails
    }

    res.status(201).json({
      success: true,
      message: 'Connection request sent successfully',
      data: {
        id: result.rows[0].id,
        senderId: result.rows[0].sender_id,
        receiverId: result.rows[0].receiver_id,
        status: result.rows[0].status,
        message: result.rows[0].message,
        createdAt: result.rows[0].created_at,
      },
    });
  } catch (error) {
    console.error('Send connection request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send connection request',
      error: error.message,
    });
  }
};

// Get user's connections
const getConnections = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    let sql = `
      SELECT 
        c.id,
        c.sender_id,
        c.receiver_id,
        c.status,
        c.message,
        c.created_at,
        c.updated_at,
        CASE 
          WHEN c.sender_id = $1 THEN p2.full_name
          ELSE p1.full_name
        END as other_user_name,
        CASE 
          WHEN c.sender_id = $1 THEN p2.profession
          ELSE p1.profession
        END as other_user_profession,
        CASE 
          WHEN c.sender_id = $1 THEN p2.avatar_url
          ELSE p1.avatar_url
        END as other_user_avatar
      FROM connections c
      LEFT JOIN professionals p1 ON c.sender_id = p1.user_id
      LEFT JOIN professionals p2 ON c.receiver_id = p2.user_id
      WHERE (c.sender_id = $1 OR c.receiver_id = $1)
    `;

    const params = [userId];
    let paramCount = 2;

    if (status) {
      sql += ` AND c.status = $${paramCount}`;
      params.push(status);
    }

    sql += ` ORDER BY c.created_at DESC`;

    const result = await query(sql, params);

    res.json({
      success: true,
      data: result.rows.map(row => ({
        id: row.id,
        senderId: row.sender_id,
        receiverId: row.receiver_id,
        status: row.status,
        message: row.message,
        otherUser: {
          name: row.other_user_name,
          profession: row.other_user_profession,
          avatar: row.other_user_avatar,
        },
        isSender: row.sender_id === userId,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      })),
    });
  } catch (error) {
    console.error('Get connections error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch connections',
      error: error.message,
    });
  }
};

// Accept connection request
const acceptConnection = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify the user is the receiver
    const connection = await query(
      'SELECT * FROM connections WHERE id = $1 AND receiver_id = $2 AND status = $3',
      [id, userId, 'pending']
    );

    if (connection.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Connection request not found or already processed',
      });
    }

    // Update connection status
    const result = await query(
      `UPDATE connections 
       SET status = 'accepted', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 
       RETURNING *`,
      [id]
    );

    // Create notification for sender
    try {
      await query(
        `INSERT INTO notifications (user_id, type, title, message, data)
         VALUES ($1, 'connection_accepted', 'Connection Accepted', $2, $3)`,
        [
          connection.rows[0].sender_id,
          'Your connection request has been accepted',
          JSON.stringify({ connectionId: id, acceptedBy: userId })
        ]
      );
    } catch (notifError) {
      console.error('Failed to create notification:', notifError);
    }

    res.json({
      success: true,
      message: 'Connection request accepted',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Accept connection error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to accept connection request',
      error: error.message,
    });
  }
};

// Reject connection request
const rejectConnection = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify the user is the receiver
    const connection = await query(
      'SELECT * FROM connections WHERE id = $1 AND receiver_id = $2 AND status = $3',
      [id, userId, 'pending']
    );

    if (connection.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Connection request not found or already processed',
      });
    }

    // Update connection status
    const result = await query(
      `UPDATE connections 
       SET status = 'rejected', updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 
       RETURNING *`,
      [id]
    );

    res.json({
      success: true,
      message: 'Connection request rejected',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Reject connection error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject connection request',
      error: error.message,
    });
  }
};

// Get available locations
const getLocations = async (req, res) => {
  try {
    const result = await query(
      `SELECT DISTINCT location 
       FROM professionals 
       WHERE location IS NOT NULL AND is_public = TRUE
       ORDER BY location`
    );

    res.json({
      success: true,
      data: ['All', ...result.rows.map(row => row.location)],
    });
  } catch (error) {
    console.error('Get locations error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch locations',
      error: error.message,
    });
  }
};

// Get available fields
const getFields = async (req, res) => {
  try {
    const result = await query(
      `SELECT DISTINCT field 
       FROM professionals 
       WHERE field IS NOT NULL AND is_public = TRUE
       ORDER BY field`
    );

    res.json({
      success: true,
      data: ['All', ...result.rows.map(row => row.field)],
    });
  } catch (error) {
    console.error('Get fields error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch fields',
      error: error.message,
    });
  }
};

module.exports = {
  getProfessionals,
  sendConnectionRequest,
  getConnections,
  acceptConnection,
  rejectConnection,
  getLocations,
  getFields,
};
