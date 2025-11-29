const { query } = require('../config/database');

// Get all business cards for current user
const getAllCards = async (req, res) => {
  try {
    const { search, favorite, limit = 50, offset = 0 } = req.query;

    let sql = `
      SELECT id, user_id, full_name, job_title, company_name, email, phone, 
             website, address, notes, color, is_favorite, created_at, updated_at
      FROM business_cards
      WHERE user_id = $1 AND is_deleted = FALSE
    `;
    const params = [req.user.id];
    let paramCount = 2;

    if (search) {
      sql += ` AND (
        full_name ILIKE $${paramCount} OR
        company_name ILIKE $${paramCount} OR
        job_title ILIKE $${paramCount} OR
        email ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
      paramCount++;
    }

    if (favorite === 'true') {
      sql += ` AND is_favorite = TRUE`;
    }

    sql += ` ORDER BY is_favorite DESC, created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(sql, params);

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as total FROM business_cards WHERE user_id = $1 AND is_deleted = FALSE',
      [req.user.id]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
      },
    });
  } catch (error) {
    console.error('Get all cards error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch business cards',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Get single business card
const getCardById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT id, user_id, full_name, job_title, company_name, email, phone,
              website, address, notes, color, is_favorite, created_at, updated_at
       FROM business_cards
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business card not found',
      });
    }

    // Get social links
    const socialLinks = await query(
      'SELECT id, platform, url, display_order FROM card_social_links WHERE card_id = $1 ORDER BY display_order',
      [id]
    );

    // Get tags
    const tags = await query(
      `SELECT t.id, t.name, t.color
       FROM tags t
       JOIN card_tags ct ON t.id = ct.tag_id
       WHERE ct.card_id = $1`,
      [id]
    );

    const card = result.rows[0];
    card.socialLinks = socialLinks.rows;
    card.tags = tags.rows;

    res.json({
      success: true,
      data: card,
    });
  } catch (error) {
    console.error('Get card by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch business card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Create new business card
const createCard = async (req, res) => {
  try {
    const {
      fullName,
      jobTitle,
      companyName,
      email,
      phone,
      website,
      address,
      notes,
      color = '#1E88E5',
      isFavorite = false,
    } = req.body;

    const result = await query(
      `INSERT INTO business_cards (
        user_id, full_name, job_title, company_name, email, phone,
        website, address, notes, color, is_favorite
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING id, user_id, full_name, job_title, company_name, email, phone,
                website, address, notes, color, is_favorite, created_at`,
      [
        req.user.id,
        fullName,
        jobTitle || null,
        companyName || null,
        email || null,
        phone || null,
        website || null,
        address || null,
        notes || null,
        color,
        isFavorite,
      ]
    );

    // Create notification for user
    await query(
      `INSERT INTO notifications (user_id, type, message) VALUES ($1, $2, $3)`,
      [
        req.user.id,
        'card_added',
        `Business card "${fullName}" was added.`
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Business card created successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Create card error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create business card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Update business card
const updateCard = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = [];
    const values = [];
    let paramCount = 1;

    // Check if card exists and belongs to user
    const existing = await query(
      'SELECT id FROM business_cards WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, req.user.id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business card not found',
      });
    }

    // Build dynamic update query
    const fields = [
      'fullName',
      'jobTitle',
      'companyName',
      'email',
      'phone',
      'website',
      'address',
      'notes',
      'color',
      'isFavorite',
    ];

    const dbFields = [
      'full_name',
      'job_title',
      'company_name',
      'email',
      'phone',
      'website',
      'address',
      'notes',
      'color',
      'is_favorite',
    ];

    fields.forEach((field, index) => {
      if (req.body[field] !== undefined) {
        updates.push(`${dbFields[index]} = $${paramCount}`);
        values.push(req.body[field]);
        paramCount++;
      }
    });

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update',
      });
    }

    values.push(id, req.user.id);

    const result = await query(
      `UPDATE business_cards
       SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramCount} AND user_id = $${paramCount + 1}
       RETURNING id, user_id, full_name, job_title, company_name, email, phone,
                 website, address, notes, color, is_favorite, updated_at`,
      values
    );

    res.json({
      success: true,
      message: 'Business card updated successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update card error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update business card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Delete business card (soft delete)
const deleteCard = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE business_cards
       SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE
       RETURNING id`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business card not found',
      });
    }

    res.json({
      success: true,
      message: 'Business card deleted successfully',
    });
  } catch (error) {
    console.error('Delete card error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete business card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Toggle favorite status
const toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE business_cards
       SET is_favorite = NOT is_favorite, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE
       RETURNING id, is_favorite`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business card not found',
      });
    }

    res.json({
      success: true,
      message: 'Favorite status updated',
      data: { isFavorite: result.rows[0].is_favorite },
    });
  } catch (error) {
    console.error('Toggle favorite error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle favorite',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Search business cards
const searchCards = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const result = await query(
      `SELECT * FROM search_business_cards($1, $2)`,
      [req.user.id, q]
    );

    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length,
    });
  } catch (error) {
    console.error('Search cards error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search business cards',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

module.exports = {
  getAllCards,
  getCardById,
  createCard,
  updateCard,
  deleteCard,
  toggleFavorite,
  searchCards,
};
