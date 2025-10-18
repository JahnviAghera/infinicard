# Infinicard Backend API

Backend REST API and PostgreSQL database for the Infinicard Flutter application.

## 🏗️ Architecture

- **Database**: PostgreSQL 16 (Alpine)
- **API**: Node.js + Express (to be implemented)
- **Admin UI**: Adminer (Database management)
- **Container Orchestration**: Docker Compose

## 📦 Database Schema

### Core Tables

1. **users** - User accounts
2. **business_cards** - Digital business cards
3. **contacts** - Contact information
4. **tags** - Categorization tags
5. **card_tags** / **contact_tags** - Many-to-many relationships
6. **card_social_links** / **contact_social_links** - Social media profiles
7. **scan_history** - OCR scan tracking
8. **sync_log** - Synchronization audit trail

### Features

- ✅ UUID primary keys
- ✅ Soft delete support (is_deleted flag)
- ✅ Automatic timestamp tracking (created_at, updated_at)
- ✅ Foreign key relationships with CASCADE
- ✅ Optimized indexes for common queries
- ✅ Full-text search functions
- ✅ Trigger-based sync logging

## 🚀 Quick Start

### Prerequisites

- Docker Desktop installed
- Docker Compose v3.8+
- Port 5432 (PostgreSQL) and 8080 (Adminer) available

### 1. Start Database

```bash
cd backend
docker-compose up -d
```

This will:
- Create PostgreSQL container with Infinicard database
- Run initialization scripts (schema, functions, seed data)
- Start Adminer web UI for database management
- Create persistent volume for data

### 2. Verify Installation

Check container status:
```bash
docker-compose ps
```

Expected output:
```
NAME                  STATUS    PORTS
infinicard_db         Up        0.0.0.0:5432->5432/tcp
infinicard_adminer    Up        0.0.0.0:8080->8080/tcp
```

### 3. Access Database Admin Panel

**Adminer Web UI**: http://localhost:8080

Login credentials:
- **System**: **PostgreSQL** (Important: NOT MySQL!)
- **Server**: `postgres`
- **Username**: `infinicard_user`
- **Password**: `infinicard_pass_2024`
- **Database**: `infinicard`

**What You Can Do in Adminer:**
- ✅ **Browse Tables** - View all data in each table
- ✅ **Edit Records** - Click any row to edit data
- ✅ **Add New Records** - Insert new rows with a form
- ✅ **Create Tables** - Design new tables with GUI
- ✅ **Modify Schema** - Add/remove columns, change types
- ✅ **Run SQL Queries** - Execute custom SQL commands
- ✅ **Import/Export** - Import SQL dumps or export data
- ✅ **View Relationships** - See foreign key connections
- ✅ **Manage Indexes** - Create/modify database indexes
- ✅ **User Management** - Create database users/permissions

📖 **See [ADMINER_GUIDE.md](ADMINER_GUIDE.md) for complete tutorial on using Adminer!**

**Direct SQL Connection** (for command line):
```bash
docker exec -it infinicard_db psql -U infinicard_user -d infinicard
```

**Note**: Port changed from 5432 to 5433 to avoid conflicts with local PostgreSQL installations.

### 4. View Sample Data

```sql
-- List all business cards
SELECT * FROM business_cards ORDER BY created_at DESC;

-- List all contacts
SELECT * FROM contacts ORDER BY created_at DESC;

-- Search cards
SELECT * FROM search_business_cards(
    '550e8400-e29b-41d4-a716-446655440000',
    'tech'
);

-- Get cards with tags
SELECT * FROM get_cards_with_tags('550e8400-e29b-41d4-a716-446655440000');
```

## 🔧 Configuration

### Database Credentials

Default credentials (change in production):
- Database: `infinicard`
- User: `infinicard_user`
- Password: `infinicard_pass_2024`
- Port: `5433` (mapped from container's 5432)
- Admin UI: http://localhost:8080

### Environment Variables

Copy `.env.example` to `.env` and customize:
```bash
cp .env.example .env
```

## 📊 Database Management

### Backup Database

```bash
docker exec infinicard_db pg_dump -U infinicard_user infinicard > backup.sql
```

### Restore Database

```bash
docker exec -i infinicard_db psql -U infinicard_user infinicard < backup.sql
```

### Reset Database

```bash
docker-compose down -v
docker-compose up -d
```

### View Logs

```bash
docker-compose logs -f postgres
```

## 🛠️ Development

### Connect from Flutter App

Update your Flutter app's database connection:

```dart
final config = DatabaseConfig(
  host: 'localhost',
  port: 5433,  // Note: Changed from default 5432
  database: 'infinicard',
  username: 'infinicard_user',
  password: 'infinicard_pass_2024',
);
```

### Useful SQL Queries

```sql
-- Count records
SELECT 
    (SELECT COUNT(*) FROM business_cards WHERE is_deleted = FALSE) as cards,
    (SELECT COUNT(*) FROM contacts WHERE is_deleted = FALSE) as contacts,
    (SELECT COUNT(*) FROM tags) as tags;

-- Recent activity
SELECT entity_type, action, COUNT(*) as count
FROM sync_log
GROUP BY entity_type, action
ORDER BY entity_type, action;

-- Favorite cards
SELECT full_name, company_name, email, phone
FROM business_cards
WHERE is_favorite = TRUE AND is_deleted = FALSE
ORDER BY full_name;
```

## 🔒 Security Notes

**⚠️ IMPORTANT FOR PRODUCTION:**

1. Change default passwords in `docker-compose.yml`
2. Use strong JWT secret in `.env`
3. Enable SSL for database connections
4. Restrict database ports (don't expose 5432 publicly)
5. Use proper password hashing (bcrypt) for user accounts
6. Implement rate limiting on API
7. Add input validation and sanitization
8. Enable database audit logging

## 📝 API Documentation (Coming Soon)

REST API endpoints will be documented here once implemented.

### Planned Endpoints

- `GET /api/cards` - List business cards
- `POST /api/cards` - Create business card
- `GET /api/cards/:id` - Get card details
- `PUT /api/cards/:id` - Update card
- `DELETE /api/cards/:id` - Soft delete card
- Similar endpoints for contacts, tags, etc.

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Change port in docker-compose.yml
ports:
  - "5433:5432"  # Use different host port
```

### Container Won't Start

```bash
docker-compose logs postgres
docker-compose down
docker-compose up -d
```

### Permission Denied

```bash
# On Linux/Mac, fix volume permissions
sudo chown -R 999:999 postgres_data/
```

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Adminer Documentation](https://www.adminer.org/)

## 📄 License

Part of the Infinicard project.
