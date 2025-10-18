# Adminer Database Admin Guide

## 🔐 Login Instructions

**URL**: http://localhost:8080

**Login Credentials:**
- **System**: Select **PostgreSQL** (not MySQL!)
- **Server**: `postgres`
- **Username**: `infinicard_user`
- **Password**: `infinicard_pass_2024`
- **Database**: `infinicard`
- ☑️ Check **Permanent login** (optional - saves credentials)

## 📊 Main Features

### 1. Browse Tables
After login, you'll see all 10 tables on the left sidebar:
- `business_cards` - Your business cards
- `contacts` - Contact information
- `users` - User accounts
- `tags` - Category tags
- `card_tags` / `contact_tags` - Relationships
- `card_social_links` / `contact_social_links` - Social media
- `scan_history` - OCR scan logs
- `sync_log` - Change tracking

**Click any table name** to view all records.

### 2. View & Edit Data

**View Records:**
1. Click table name in left sidebar
2. See all rows with data
3. Click "Show: 50" dropdown to show more/less rows
4. Use search box to filter results

**Edit a Record:**
1. Click any row's **edit** link (pencil icon)
2. Modify fields in the form
3. Click **Save** button
4. Data is updated instantly

**Delete a Record:**
1. Check the checkbox next to row(s)
2. Click **Delete** button at bottom
3. Confirm deletion

### 3. Add New Records

**Insert New Data:**
1. Click table name
2. Click **New item** link (top of page)
3. Fill in the form:
   - Leave `id` blank (auto-generated UUID)
   - Fill required fields (marked with *)
   - Optional fields can be empty
4. Click **Save**

**Example - Add New Business Card:**
```
id: [leave blank]
user_id: 550e8400-e29b-41d4-a716-446655440000
full_name: Jane Smith
job_title: CTO
company_name: Tech Innovations
email: jane@techinnovations.com
phone: +1-555-9999
color: #4CAF50
is_favorite: [check if favorite]
```

### 4. Create New Tables

**Add a Table:**
1. Click **Create table** link (left sidebar)
2. Enter table name (e.g., `custom_fields`)
3. Add columns:
   - Column name (e.g., `id`, `name`, `value`)
   - Type (UUID, VARCHAR, TEXT, INTEGER, etc.)
   - Length (for VARCHAR)
   - Check NULL/NOT NULL
   - Set default values
4. Define primary key
5. Click **Save**

**Example - Create Custom Table:**
```sql
Table name: app_settings

Columns:
- id: UUID, NOT NULL, Primary Key, DEFAULT uuid_generate_v4()
- setting_key: VARCHAR(100), NOT NULL, UNIQUE
- setting_value: TEXT
- created_at: TIMESTAMP WITH TIME ZONE, DEFAULT CURRENT_TIMESTAMP
- updated_at: TIMESTAMP WITH TIME ZONE, DEFAULT CURRENT_TIMESTAMP
```

### 5. Modify Table Schema

**Add Column to Existing Table:**
1. Click table name
2. Click **Alter table** link
3. Scroll to "Add column" section
4. Enter column details
5. Click **Save**

**Example - Add Column:**
- Table: `business_cards`
- New column: `linkedin_url`
- Type: VARCHAR(500)
- NULL: Yes

**Remove Column:**
1. Click **Alter table**
2. Find column in list
3. Click **Drop** link next to it
4. Confirm

### 6. Run SQL Queries

**Execute Custom SQL:**
1. Click **SQL command** link (left sidebar)
2. Enter your SQL query:
```sql
-- Search cards
SELECT * FROM business_cards 
WHERE company_name ILIKE '%tech%';

-- Count records
SELECT COUNT(*) FROM contacts;

-- Join tables
SELECT bc.full_name, t.name as tag
FROM business_cards bc
JOIN card_tags ct ON bc.id = ct.card_id
JOIN tags t ON ct.tag_id = t.id;
```
3. Click **Execute** button
4. View results below

**Useful Queries:**

```sql
-- All favorite cards
SELECT full_name, company_name, email 
FROM business_cards 
WHERE is_favorite = TRUE AND is_deleted = FALSE;

-- Recent contacts
SELECT first_name, last_name, company 
FROM contacts 
ORDER BY created_at DESC 
LIMIT 10;

-- Cards with tags
SELECT bc.full_name, STRING_AGG(t.name, ', ') as tags
FROM business_cards bc
LEFT JOIN card_tags ct ON bc.id = ct.card_id
LEFT JOIN tags t ON ct.tag_id = t.id
GROUP BY bc.id, bc.full_name;

-- Scan statistics
SELECT 
    DATE(scan_date) as date,
    COUNT(*) as scans,
    AVG(processing_time_ms) as avg_time_ms
FROM scan_history
GROUP BY DATE(scan_date)
ORDER BY date DESC;
```

### 7. Import Data

**Import SQL Dump:**
1. Click **Import** link (left sidebar)
2. Click **Choose File**
3. Select your `.sql` file
4. Click **Execute**

**Import CSV:**
1. Go to specific table
2. Click **Import**
3. Upload CSV file
4. Map columns
5. Click **Import**

### 8. Export Data

**Export Database:**
1. Click **Export** link (left sidebar)
2. Select format:
   - **SQL** - Full database dump
   - **CSV** - Spreadsheet format
   - **CSV;** - Alternative CSV
3. Choose options:
   - Output: Save / Open / gzip
   - Format: INSERT / UPDATE
4. Click **Export**

**Export Single Table:**
1. Open table
2. Click **Export** link
3. Choose format and options
4. Click **Export**

### 9. Search Data

**Search Within Table:**
1. Open any table
2. Click **Search** link (top of page)
3. Enter search criteria:
   - Field to search
   - Operator (=, LIKE, >, <, etc.)
   - Value
4. Click **Select** to search

**Example - Find Cards:**
```
Field: company_name
Operator: LIKE
Value: %Tech%
```

### 10. Manage Relationships

**View Foreign Keys:**
1. Click table name
2. See "Foreign keys" section
3. View relationships to other tables

**Add Foreign Key:**
1. Click **Alter table**
2. Scroll to "Foreign keys" section
3. Define:
   - Source column
   - Target table
   - Target column
   - ON DELETE / ON UPDATE actions
4. Click **Save**

## 🎨 Advanced Features

### Create View
1. Click **Create view** (left sidebar)
2. Enter view name
3. Enter SELECT query
4. Click **Save**

### Create Index
1. Open table
2. Click **Indexes** link
3. Click **Alter indexes**
4. Add new index with columns
5. Click **Save**

### Triggers & Functions
- Click **SQL command**
- Create custom triggers/functions
- See examples in `02-create-functions.sql`

## 🔒 Security Tips

1. **Change default password** in production
2. **Disable Adminer** in production or restrict access
3. **Use SSL** for remote connections
4. **Regular backups** using Export feature
5. **Test queries** on development data first

## 📱 Mobile Access

Adminer works on mobile browsers:
- Access from phone/tablet
- Use same URL: http://localhost:8080
- Responsive interface

## ⚡ Quick Actions Cheatsheet

| Action | Steps |
|--------|-------|
| View table data | Click table name |
| Edit row | Click row, modify, Save |
| Add row | Table → New item → Fill form → Save |
| Delete rows | Check boxes → Delete |
| Run SQL | SQL command → Type query → Execute |
| Search | Open table → Search → Enter criteria |
| Export | Export link → Choose format → Export |
| Import | Import link → Choose file → Execute |
| Create table | Create table → Define columns → Save |
| Add column | Table → Alter table → Add column |

## 🆘 Troubleshooting

**Can't login?**
- Verify Docker containers are running: `docker-compose ps`
- Check credentials match docker-compose.yml
- Select **PostgreSQL** not MySQL

**Table not showing data?**
- Check "Show: 50" - increase limit
- Verify data exists: Run `SELECT COUNT(*) FROM table_name`

**Changes not saving?**
- Check for validation errors
- Verify field types match
- Check foreign key constraints

**Performance slow?**
- Add indexes on frequently searched columns
- Use LIMIT in queries
- Check Docker container resources

## 📖 Learn More

- [Adminer Documentation](https://www.adminer.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- See `README.md` for database schema details
