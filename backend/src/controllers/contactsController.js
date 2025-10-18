const { query } = require('../config/database');

// Get all contacts for current user
const getAllContacts = async (req, res) => {
  try {
    const { search, favorite, limit = 50, offset = 0 } = req.query;

    let sql = `
      SELECT id, user_id, first_name, last_name, company, job_title, email, 
             phone, mobile, fax, website, address_line1, address_line2, city, 
             state, postal_code, country, notes, is_favorite, created_at, updated_at
      FROM contacts
      WHERE user_id = $1 AND is_deleted = FALSE
    `;
    const params = [req.user.id];
    let paramCount = 2;

    if (search) {
      sql += ` AND (
        first_name ILIKE $${paramCount} OR
        last_name ILIKE $${paramCount} OR
        company ILIKE $${paramCount} OR
        email ILIKE $${paramCount}
      )`;
      params.push(`%${search}%`);
      paramCount++;
    }

    if (favorite === 'true') {
      sql += ` AND is_favorite = TRUE`;
    }

    sql += ` ORDER BY is_favorite DESC, first_name ASC, last_name ASC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(sql, params);

    // Get total count
    const countResult = await query(
      'SELECT COUNT(*) as total FROM contacts WHERE user_id = $1 AND is_deleted = FALSE',
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
    console.error('Get all contacts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch contacts',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Get single contact
const getContactById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT id, user_id, first_name, last_name, company, job_title, email,
              phone, mobile, fax, website, address_line1, address_line2, city,
              state, postal_code, country, notes, is_favorite, created_at, updated_at
       FROM contacts
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found',
      });
    }

    // Get social links
    const socialLinks = await query(
      'SELECT id, platform, url, display_order FROM contact_social_links WHERE contact_id = $1 ORDER BY display_order',
      [id]
    );

    // Get tags
    const tags = await query(
      `SELECT t.id, t.name, t.color
       FROM tags t
       JOIN contact_tags ct ON t.id = ct.tag_id
       WHERE ct.contact_id = $1`,
      [id]
    );

    const contact = result.rows[0];
    contact.socialLinks = socialLinks.rows;
    contact.tags = tags.rows;

    res.json({
      success: true,
      data: contact,
    });
  } catch (error) {
    console.error('Get contact by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Create new contact
const createContact = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      company,
      jobTitle,
      email,
      phone,
      mobile,
      fax,
      website,
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
      notes,
      isFavorite = false,
    } = req.body;

    const result = await query(
      `INSERT INTO contacts (
        user_id, first_name, last_name, company, job_title, email, phone,
        mobile, fax, website, address_line1, address_line2, city, state,
        postal_code, country, notes, is_favorite
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
      RETURNING id, user_id, first_name, last_name, company, job_title, email, phone,
                mobile, fax, website, is_favorite, created_at`,
      [
        req.user.id,
        firstName,
        lastName || null,
        company || null,
        jobTitle || null,
        email || null,
        phone || null,
        mobile || null,
        fax || null,
        website || null,
        addressLine1 || null,
        addressLine2 || null,
        city || null,
        state || null,
        postalCode || null,
        country || null,
        notes || null,
        isFavorite,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Contact created successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Create contact error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Update contact
const updateContact = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = [];
    const values = [];
    let paramCount = 1;

    // Check if contact exists and belongs to user
    const existing = await query(
      'SELECT id FROM contacts WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, req.user.id]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found',
      });
    }

    // Build dynamic update query
    const fieldMapping = {
      firstName: 'first_name',
      lastName: 'last_name',
      company: 'company',
      jobTitle: 'job_title',
      email: 'email',
      phone: 'phone',
      mobile: 'mobile',
      fax: 'fax',
      website: 'website',
      addressLine1: 'address_line1',
      addressLine2: 'address_line2',
      city: 'city',
      state: 'state',
      postalCode: 'postal_code',
      country: 'country',
      notes: 'notes',
      isFavorite: 'is_favorite',
    };

    Object.entries(fieldMapping).forEach(([camelCase, snakeCase]) => {
      if (req.body[camelCase] !== undefined) {
        updates.push(`${snakeCase} = $${paramCount}`);
        values.push(req.body[camelCase]);
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
      `UPDATE contacts
       SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramCount} AND user_id = $${paramCount + 1}
       RETURNING id, user_id, first_name, last_name, company, job_title, email, phone,
                 mobile, is_favorite, updated_at`,
      values
    );

    res.json({
      success: true,
      message: 'Contact updated successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update contact error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Delete contact (soft delete)
const deleteContact = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE contacts
       SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE
       RETURNING id`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found',
      });
    }

    res.json({
      success: true,
      message: 'Contact deleted successfully',
    });
  } catch (error) {
    console.error('Delete contact error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Toggle favorite status
const toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE contacts
       SET is_favorite = NOT is_favorite, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE
       RETURNING id, is_favorite`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found',
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

// Search contacts
const searchContacts = async (req, res) => {
  try {
    const { q } = req.query;

    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const result = await query(
      `SELECT * FROM search_contacts($1, $2)`,
      [req.user.id, q]
    );

    res.json({
      success: true,
      data: result.rows,
      count: result.rows.length,
    });
  } catch (error) {
    console.error('Search contacts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search contacts',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

module.exports = {
  getAllContacts,
  getContactById,
  createContact,
  updateContact,
  deleteContact,
  toggleFavorite,
  searchContacts,
};
