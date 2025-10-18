-- Infinicard Database Functions and Triggers

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at columns
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_business_cards_updated_at
    BEFORE UPDATE ON business_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to log sync events
CREATE OR REPLACE FUNCTION log_sync_event()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (NEW.user_id, TG_TABLE_NAME, NEW.id, 'create');
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (NEW.user_id, TG_TABLE_NAME, NEW.id, 'update');
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sync_log (user_id, entity_type, entity_id, action)
        VALUES (OLD.user_id, TG_TABLE_NAME, OLD.id, 'delete');
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for sync logging
CREATE TRIGGER sync_log_business_cards
    AFTER INSERT OR UPDATE OR DELETE ON business_cards
    FOR EACH ROW
    EXECUTE FUNCTION log_sync_event();

CREATE TRIGGER sync_log_contacts
    AFTER INSERT OR UPDATE OR DELETE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION log_sync_event();

-- Function to search business cards
CREATE OR REPLACE FUNCTION search_business_cards(
    p_user_id UUID,
    p_search_term VARCHAR(255)
)
RETURNS TABLE (
    id UUID,
    full_name VARCHAR(255),
    job_title VARCHAR(255),
    company_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    color VARCHAR(20),
    is_favorite BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id,
        bc.full_name,
        bc.job_title,
        bc.company_name,
        bc.email,
        bc.phone,
        bc.color,
        bc.is_favorite,
        bc.created_at
    FROM business_cards bc
    WHERE bc.user_id = p_user_id
        AND bc.is_deleted = FALSE
        AND (
            bc.full_name ILIKE '%' || p_search_term || '%'
            OR bc.company_name ILIKE '%' || p_search_term || '%'
            OR bc.job_title ILIKE '%' || p_search_term || '%'
            OR bc.email ILIKE '%' || p_search_term || '%'
            OR bc.phone ILIKE '%' || p_search_term || '%'
        )
    ORDER BY bc.is_favorite DESC, bc.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to search contacts
CREATE OR REPLACE FUNCTION search_contacts(
    p_user_id UUID,
    p_search_term VARCHAR(255)
)
RETURNS TABLE (
    id UUID,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    company VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    is_favorite BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.company,
        c.email,
        c.phone,
        c.is_favorite,
        c.created_at
    FROM contacts c
    WHERE c.user_id = p_user_id
        AND c.is_deleted = FALSE
        AND (
            c.first_name ILIKE '%' || p_search_term || '%'
            OR c.last_name ILIKE '%' || p_search_term || '%'
            OR c.company ILIKE '%' || p_search_term || '%'
            OR c.email ILIKE '%' || p_search_term || '%'
            OR c.phone ILIKE '%' || p_search_term || '%'
        )
    ORDER BY c.is_favorite DESC, c.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get cards with tags
CREATE OR REPLACE FUNCTION get_cards_with_tags(p_user_id UUID)
RETURNS TABLE (
    card_id UUID,
    full_name VARCHAR(255),
    company_name VARCHAR(255),
    tags JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bc.id,
        bc.full_name,
        bc.company_name,
        COALESCE(
            json_agg(
                json_build_object('id', t.id, 'name', t.name, 'color', t.color)
            ) FILTER (WHERE t.id IS NOT NULL),
            '[]'::json
        ) AS tags
    FROM business_cards bc
    LEFT JOIN card_tags ct ON bc.id = ct.card_id
    LEFT JOIN tags t ON ct.tag_id = t.id
    WHERE bc.user_id = p_user_id AND bc.is_deleted = FALSE
    GROUP BY bc.id, bc.full_name, bc.company_name
    ORDER BY bc.created_at DESC;
END;
$$ LANGUAGE plpgsql;
