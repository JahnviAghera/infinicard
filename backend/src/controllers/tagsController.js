const { query } = require('../config/database');

// Get all tags for current user
const getAllTags = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, color, created_at
       FROM tags
       WHERE user_id = $1
       ORDER BY name ASC`,
      [req.user.id]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (error) {
    console.error('Get all tags error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tags',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Create new tag
const createTag = async (req, res) => {
  try {
    const { name, color = '#1E88E5' } = req.body;

    // Check if tag with same name already exists
    const existing = await query(
      'SELECT id FROM tags WHERE user_id = $1 AND name = $2',
      [req.user.id, name]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Tag with this name already exists',
      });
    }

    const result = await query(
      `INSERT INTO tags (user_id, name, color)
       VALUES ($1, $2, $3)
       RETURNING id, name, color, created_at`,
      [req.user.id, name, color]
    );

    res.status(201).json({
      success: true,
      message: 'Tag created successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Create tag error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create tag',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Update tag
const updateTag = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, color } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramCount}`);
      values.push(name);
      paramCount++;
    }

    if (color !== undefined) {
      updates.push(`color = $${paramCount}`);
      values.push(color);
      paramCount++;
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No fields to update',
      });
    }

    values.push(id, req.user.id);

    const result = await query(
      `UPDATE tags
       SET ${updates.join(', ')}
       WHERE id = $${paramCount} AND user_id = $${paramCount + 1}
       RETURNING id, name, color`,
      values
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag not found',
      });
    }

    res.json({
      success: true,
      message: 'Tag updated successfully',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update tag error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update tag',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Delete tag
const deleteTag = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      'DELETE FROM tags WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag not found',
      });
    }

    res.json({
      success: true,
      message: 'Tag deleted successfully',
    });
  } catch (error) {
    console.error('Delete tag error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete tag',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Add tag to business card
const addTagToCard = async (req, res) => {
  try {
    const { cardId, tagId } = req.params;

    // Verify card belongs to user
    const card = await query(
      'SELECT id FROM business_cards WHERE id = $1 AND user_id = $2',
      [cardId, req.user.id]
    );

    if (card.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Business card not found',
      });
    }

    // Verify tag belongs to user
    const tag = await query(
      'SELECT id FROM tags WHERE id = $1 AND user_id = $2',
      [tagId, req.user.id]
    );

    if (tag.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag not found',
      });
    }

    // Add tag to card (ignore if already exists)
    await query(
      `INSERT INTO card_tags (card_id, tag_id)
       VALUES ($1, $2)
       ON CONFLICT (card_id, tag_id) DO NOTHING`,
      [cardId, tagId]
    );

    res.json({
      success: true,
      message: 'Tag added to business card',
    });
  } catch (error) {
    console.error('Add tag to card error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add tag to card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Remove tag from business card
const removeTagFromCard = async (req, res) => {
  try {
    const { cardId, tagId } = req.params;

    const result = await query(
      `DELETE FROM card_tags
       WHERE card_id = $1 AND tag_id = $2
       AND EXISTS (SELECT 1 FROM business_cards WHERE id = $1 AND user_id = $3)
       RETURNING card_id`,
      [cardId, tagId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag association not found',
      });
    }

    res.json({
      success: true,
      message: 'Tag removed from business card',
    });
  } catch (error) {
    console.error('Remove tag from card error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove tag from card',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Add tag to contact
const addTagToContact = async (req, res) => {
  try {
    const { contactId, tagId } = req.params;

    // Verify contact belongs to user
    const contact = await query(
      'SELECT id FROM contacts WHERE id = $1 AND user_id = $2',
      [contactId, req.user.id]
    );

    if (contact.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Contact not found',
      });
    }

    // Verify tag belongs to user
    const tag = await query(
      'SELECT id FROM tags WHERE id = $1 AND user_id = $2',
      [tagId, req.user.id]
    );

    if (tag.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag not found',
      });
    }

    // Add tag to contact
    await query(
      `INSERT INTO contact_tags (contact_id, tag_id)
       VALUES ($1, $2)
       ON CONFLICT (contact_id, tag_id) DO NOTHING`,
      [contactId, tagId]
    );

    res.json({
      success: true,
      message: 'Tag added to contact',
    });
  } catch (error) {
    console.error('Add tag to contact error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add tag to contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

// Remove tag from contact
const removeTagFromContact = async (req, res) => {
  try {
    const { contactId, tagId } = req.params;

    const result = await query(
      `DELETE FROM contact_tags
       WHERE contact_id = $1 AND tag_id = $2
       AND EXISTS (SELECT 1 FROM contacts WHERE id = $1 AND user_id = $3)
       RETURNING contact_id`,
      [contactId, tagId, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tag association not found',
      });
    }

    res.json({
      success: true,
      message: 'Tag removed from contact',
    });
  } catch (error) {
    console.error('Remove tag from contact error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove tag from contact',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

module.exports = {
  getAllTags,
  createTag,
  updateTag,
  deleteTag,
  addTagToCard,
  removeTagFromCard,
  addTagToContact,
  removeTagFromContact,
};
