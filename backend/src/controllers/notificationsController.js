const { query } = require('../config/database');

// Get all notifications for current user
const getNotifications = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, type, message, is_read, created_at FROM notifications WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.user.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// Mark notification as read
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2 RETURNING id, is_read`,
      [id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark notification as read' });
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      `DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id`,
      [id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
};

module.exports = { getNotifications, markAsRead, deleteNotification };
