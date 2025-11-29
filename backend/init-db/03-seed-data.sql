-- Infinicard Seed Data
-- Sample data for development and testing

-- Create demo user
INSERT INTO users (id, email, username, password_hash, full_name, is_active)
VALUES (
    '550e8400-e29b-41d4-a716-446655440000',
    'demo@infinicard.com',
    'demo_user',
    '$2a$10$YourHashedPasswordHere', -- In production, use proper password hashing
    'Demo User',
    TRUE
) ON CONFLICT (email) DO NOTHING;

-- Sample business cards
INSERT INTO business_cards (user_id, full_name, job_title, company_name, email, phone, website, address, color, is_favorite)
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'John Anderson',
        'Senior Software Engineer',
        'TechCorp Solutions',
        'john.anderson@techcorp.com',
        '+1-555-0101',
        'https://techcorp.com',
        '123 Tech Street, Silicon Valley, CA 94025',
        '#1E88E5',
        TRUE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Sarah Mitchell',
        'Product Manager',
        'InnovateLabs',
        'sarah.mitchell@innovatelabs.com',
        '+1-555-0102',
        'https://innovatelabs.io',
        '456 Innovation Ave, Austin, TX 78701',
        '#4CAF50',
        FALSE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Michael Chen',
        'UX Designer',
        'DesignHub Studio',
        'michael.chen@designhub.com',
        '+1-555-0103',
        'https://designhub.design',
        '789 Creative Blvd, Portland, OR 97201',
        '#9C27B0',
        TRUE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Emily Rodriguez',
        'Marketing Director',
        'BrandWorks Agency',
        'emily.rodriguez@brandworks.com',
        '+1-555-0104',
        'https://brandworks.co',
        '321 Marketing Plaza, New York, NY 10001',
        '#FF9800',
        FALSE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'David Thompson',
        'CEO & Founder',
        'StartupVentures',
        'david@startupventures.io',
        '+1-555-0105',
        'https://startupventures.io',
        '555 Entrepreneur Way, San Francisco, CA 94105',
        '#F44336',
        TRUE
    );

-- Sample contacts
INSERT INTO contacts (user_id, first_name, last_name, company, job_title, email, phone, mobile, city, state, country, is_favorite)
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Jessica',
        'Taylor',
        'Global Consulting',
        'Senior Consultant',
        'jessica.taylor@globalconsulting.com',
        '+1-555-0201',
        '+1-555-0202',
        'Boston',
        'Massachusetts',
        'USA',
        TRUE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Robert',
        'Williams',
        'Finance Corp',
        'Financial Analyst',
        'robert.williams@financecorp.com',
        '+1-555-0203',
        '+1-555-0204',
        'Chicago',
        'Illinois',
        'USA',
        FALSE
    ),
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'Amanda',
        'Brown',
        'Healthcare Solutions',
        'Director of Operations',
        'amanda.brown@healthcaresol.com',
        '+1-555-0205',
        '+1-555-0206',
        'Seattle',
        'Washington',
        'USA',
        TRUE
    );

-- Sample tags
INSERT INTO tags (user_id, name, color)
VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'Client', '#1E88E5'),
    ('550e8400-e29b-41d4-a716-446655440000', 'Partner', '#4CAF50'),
    ('550e8400-e29b-41d4-a716-446655440000', 'Vendor', '#FF9800'),
    ('550e8400-e29b-41d4-a716-446655440000', 'Colleague', '#9C27B0'),
    ('550e8400-e29b-41d4-a716-446655440000', 'Urgent', '#F44336');

-- Associate tags with some cards
INSERT INTO card_tags (card_id, tag_id)
SELECT 
    bc.id,
    t.id
FROM business_cards bc
CROSS JOIN tags t
WHERE bc.full_name = 'John Anderson' AND t.name IN ('Client', 'Urgent')
   OR bc.full_name = 'Sarah Mitchell' AND t.name = 'Partner'
   OR bc.full_name = 'Michael Chen' AND t.name = 'Colleague';

-- Sample social links
INSERT INTO card_social_links (card_id, platform, url, display_order)
SELECT 
    bc.id,
    'linkedin',
    'https://linkedin.com/in/john-anderson',
    1
FROM business_cards bc
WHERE bc.full_name = 'John Anderson';

INSERT INTO card_social_links (card_id, platform, url, display_order)
SELECT 
    bc.id,
    'twitter',
    'https://twitter.com/sarahmitchell',
    1
FROM business_cards bc
WHERE bc.full_name = 'Sarah Mitchell';
