# Infinicard API Documentation

Complete REST API documentation with authentication for the Infinicard Flutter application.

## 🔗 Base URL

```
http://localhost:3000/api
```

## 🔐 Authentication

All endpoints except `/auth/register` and `/auth/login` require a JWT Bearer token.

### Request Header
```http
Authorization: Bearer <your_jwt_token>
```

### Token Expiry
- Access Token: 7 days
- Refresh Token: 30 days

---

## 📋 API Endpoints

### Authentication

#### 1. Register User
Create a new user account.

**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePassword123",
  "fullName": "John Doe"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "username": "johndoe",
      "fullName": "John Doe",
      "createdAt": "2025-10-18T08:30:00.000Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Errors:**
- `409 Conflict` - Email or username already exists
- `400 Bad Request` - Validation error

---

#### 2. Login User
Authenticate and get access token.

**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "username": "johndoe",
      "fullName": "John Doe"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Errors:**
- `401 Unauthorized` - Invalid credentials
- `403 Forbidden` - Account inactive

---

#### 3. Get Profile
Get current user's profile information.

**Endpoint:** `GET /api/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "johndoe",
    "fullName": "John Doe",
    "createdAt": "2025-10-18T08:30:00.000Z",
    "lastLogin": "2025-10-18T09:15:00.000Z"
  }
}
```

---

#### 4. Update Profile
Update user profile information.

**Endpoint:** `PUT /api/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "fullName": "John Michael Doe"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "johndoe",
    "fullName": "John Michael Doe",
    "updatedAt": "2025-10-18T10:00:00.000Z"
  }
}
```

---

#### 5. Change Password
Change user password.

**Endpoint:** `POST /api/auth/change-password`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "currentPassword": "OldPassword123",
  "newPassword": "NewPassword456"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

**Errors:**
- `401 Unauthorized` - Current password incorrect

---

### Business Cards

#### 1. Get All Cards
Retrieve all business cards for the authenticated user.

**Endpoint:** `GET /api/cards`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `search` (optional) - Search term for name, company, email
- `favorite` (optional) - `true` to get only favorites
- `limit` (optional) - Results per page (default: 50)
- `offset` (optional) - Pagination offset (default: 0)

**Example:** `GET /api/cards?search=tech&favorite=true&limit=20&offset=0`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "card-uuid-1",
      "user_id": "user-uuid",
      "full_name": "John Anderson",
      "job_title": "Senior Software Engineer",
      "company_name": "TechCorp Solutions",
      "email": "john.anderson@techcorp.com",
      "phone": "+1-555-0101",
      "website": "https://techcorp.com",
      "address": "123 Tech Street, Silicon Valley, CA",
      "notes": "Met at tech conference 2025",
      "color": "#1E88E5",
      "is_favorite": true,
      "created_at": "2025-10-15T10:00:00.000Z",
      "updated_at": "2025-10-15T10:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 42,
    "limit": 50,
    "offset": 0
  }
}
```

---

#### 2. Get Card by ID
Get a single business card with full details.

**Endpoint:** `GET /api/cards/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "card-uuid-1",
    "user_id": "user-uuid",
    "full_name": "John Anderson",
    "job_title": "Senior Software Engineer",
    "company_name": "TechCorp Solutions",
    "email": "john.anderson@techcorp.com",
    "phone": "+1-555-0101",
    "website": "https://techcorp.com",
    "address": "123 Tech Street",
    "notes": "Met at conference",
    "color": "#1E88E5",
    "is_favorite": true,
    "created_at": "2025-10-15T10:00:00.000Z",
    "updated_at": "2025-10-15T10:00:00.000Z",
    "socialLinks": [
      {
        "id": "link-uuid",
        "platform": "linkedin",
        "url": "https://linkedin.com/in/john-anderson",
        "display_order": 1
      }
    ],
    "tags": [
      {
        "id": "tag-uuid",
        "name": "Client",
        "color": "#4CAF50"
      }
    ]
  }
}
```

**Errors:**
- `404 Not Found` - Card doesn't exist or doesn't belong to user

---

#### 3. Create Business Card
Create a new business card.

**Endpoint:** `POST /api/cards`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "fullName": "Sarah Mitchell",
  "jobTitle": "Product Manager",
  "companyName": "InnovateLabs",
  "email": "sarah@innovatelabs.com",
  "phone": "+1-555-0102",
  "website": "https://innovatelabs.io",
  "address": "456 Innovation Ave, Austin, TX",
  "notes": "Interested in collaboration",
  "color": "#4CAF50",
  "isFavorite": false
}
```

**Required Fields:**
- `fullName` (string, max 255)

**Optional Fields:**
- `jobTitle` (string, max 255)
- `companyName` (string, max 255)
- `email` (valid email)
- `phone` (string, max 50)
- `website` (valid URL, max 500)
- `address` (text)
- `notes` (text)
- `color` (hex color, default: #1E88E5)
- `isFavorite` (boolean, default: false)

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Business card created successfully",
  "data": {
    "id": "new-card-uuid",
    "user_id": "user-uuid",
    "full_name": "Sarah Mitchell",
    "job_title": "Product Manager",
    "company_name": "InnovateLabs",
    "email": "sarah@innovatelabs.com",
    "phone": "+1-555-0102",
    "website": "https://innovatelabs.io",
    "address": "456 Innovation Ave, Austin, TX",
    "notes": "Interested in collaboration",
    "color": "#4CAF50",
    "is_favorite": false,
    "created_at": "2025-10-18T11:00:00.000Z"
  }
}
```

---

#### 4. Update Business Card
Update an existing business card.

**Endpoint:** `PUT /api/cards/:id`

**Headers:** `Authorization: Bearer <token>`

**Request Body:** (all fields optional)
```json
{
  "fullName": "Sarah J. Mitchell",
  "jobTitle": "Senior Product Manager",
  "isFavorite": true
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Business card updated successfully",
  "data": {
    "id": "card-uuid",
    "user_id": "user-uuid",
    "full_name": "Sarah J. Mitchell",
    "job_title": "Senior Product Manager",
    "is_favorite": true,
    "updated_at": "2025-10-18T12:00:00.000Z"
  }
}
```

**Errors:**
- `404 Not Found` - Card doesn't exist
- `400 Bad Request` - No fields to update

---

#### 5. Delete Business Card
Soft delete a business card.

**Endpoint:** `DELETE /api/cards/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Business card deleted successfully"
}
```

**Errors:**
- `404 Not Found` - Card doesn't exist

---

#### 6. Toggle Favorite
Toggle favorite status of a business card.

**Endpoint:** `PATCH /api/cards/:id/favorite`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Favorite status updated",
  "data": {
    "isFavorite": true
  }
}
```

---

#### 7. Search Cards
Search business cards using full-text search.

**Endpoint:** `GET /api/cards/search`

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `q` (required) - Search query

**Example:** `GET /api/cards/search?q=tech`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "card-uuid",
      "full_name": "John Anderson",
      "job_title": "Senior Software Engineer",
      "company_name": "TechCorp Solutions",
      "email": "john.anderson@techcorp.com",
      "phone": "+1-555-0101",
      "color": "#1E88E5",
      "is_favorite": true,
      "created_at": "2025-10-15T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

---

### Contacts

The Contacts API follows the same pattern as Business Cards with similar endpoints:

- `GET /api/contacts` - Get all contacts
- `GET /api/contacts/:id` - Get contact by ID
- `POST /api/contacts` - Create contact
- `PUT /api/contacts/:id` - Update contact
- `DELETE /api/contacts/:id` - Delete contact
- `PATCH /api/contacts/:id/favorite` - Toggle favorite
- `GET /api/contacts/search?q=query` - Search contacts

**Contact Fields:**
```json
{
  "firstName": "Jessica",
  "lastName": "Taylor",
  "company": "Global Consulting",
  "jobTitle": "Senior Consultant",
  "email": "jessica@globalconsulting.com",
  "phone": "+1-555-0201",
  "mobile": "+1-555-0202",
  "fax": "+1-555-0203",
  "website": "https://globalconsulting.com",
  "addressLine1": "789 Business Blvd",
  "addressLine2": "Suite 100",
  "city": "Boston",
  "state": "Massachusetts",
  "postalCode": "02101",
  "country": "USA",
  "notes": "Key account contact",
  "isFavorite": false
}
```

---

### Tags

#### 1. Get All Tags
Get all tags for the authenticated user.

**Endpoint:** `GET /api/tags`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": "tag-uuid-1",
      "name": "Client",
      "color": "#1E88E5",
      "created_at": "2025-10-15T10:00:00.000Z"
    },
    {
      "id": "tag-uuid-2",
      "name": "Partner",
      "color": "#4CAF50",
      "created_at": "2025-10-15T11:00:00.000Z"
    }
  ]
}
```

---

#### 2. Create Tag
Create a new tag.

**Endpoint:** `POST /api/tags`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "VIP",
  "color": "#FF9800"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Tag created successfully",
  "data": {
    "id": "new-tag-uuid",
    "name": "VIP",
    "color": "#FF9800",
    "created_at": "2025-10-18T13:00:00.000Z"
  }
}
```

**Errors:**
- `409 Conflict` - Tag with this name already exists

---

#### 3. Update Tag
Update an existing tag.

**Endpoint:** `PUT /api/tags/:id`

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "VIP Client",
  "color": "#F44336"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag updated successfully",
  "data": {
    "id": "tag-uuid",
    "name": "VIP Client",
    "color": "#F44336"
  }
}
```

---

#### 4. Delete Tag
Delete a tag (and remove all associations).

**Endpoint:** `DELETE /api/tags/:id`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag deleted successfully"
}
```

---

#### 5. Add Tag to Card
Associate a tag with a business card.

**Endpoint:** `POST /api/tags/cards/:cardId/tags/:tagId`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag added to business card"
}
```

---

#### 6. Remove Tag from Card
Remove tag association from a business card.

**Endpoint:** `DELETE /api/tags/cards/:cardId/tags/:tagId`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag removed from business card"
}
```

---

#### 7. Add Tag to Contact
Associate a tag with a contact.

**Endpoint:** `POST /api/tags/contacts/:contactId/tags/:tagId`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag added to contact"
}
```

---

#### 8. Remove Tag from Contact
Remove tag association from a contact.

**Endpoint:** `DELETE /api/tags/contacts/:contactId/tags/:tagId`

**Headers:** `Authorization: Bearer <token>`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Tag removed from contact"
}
```

---

## 🔒 Error Responses

### Standard Error Format
```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email address"
    }
  ]
}
```

### HTTP Status Codes
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - Access denied
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## 📊 Rate Limiting

- **Window:** 15 minutes
- **Max Requests:** 100 per IP
- **Response:** `429 Too Many Requests`

---

## 🧪 Testing with cURL

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "Test123456",
    "fullName": "Test User"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123456"
  }'
```

### Get All Cards (with token)
```bash
curl -X GET http://localhost:3000/api/cards \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Create Card
```bash
curl -X POST http://localhost:3000/api/cards \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Jane Smith",
    "jobTitle": "CTO",
    "companyName": "Tech Innovations",
    "email": "jane@techinnovations.com",
    "phone": "+1-555-9999",
    "color": "#9C27B0",
    "isFavorite": true
  }'
```

---

## 🔧 Development Tools

### Postman Collection
Import the included `Infinicard_API.postman_collection.json` for easy testing.

### Environment Variables
```env
BASE_URL=http://localhost:3000
ACCESS_TOKEN=<your_token_here>
```

---

## 📝 Notes

1. All timestamps are in ISO 8601 format (UTC)
2. UUIDs are auto-generated for all resources
3. Soft deletes are used (records marked as deleted but not removed)
4. Pagination defaults: limit=50, offset=0
5. Search is case-insensitive
6. Colors must be valid hex codes (#RRGGBB)

---

## 🆘 Support

For issues or questions:
- Check the [README.md](README.md)
- Review the [ADMINER_GUIDE.md](ADMINER_GUIDE.md)
- Contact: support@infinicard.com
