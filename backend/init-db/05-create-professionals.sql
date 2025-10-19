-- Create professionals table for discover feature
CREATE TABLE IF NOT EXISTS professionals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    profession VARCHAR(255),
    location VARCHAR(255),
    field VARCHAR(255),
    avatar_url TEXT,
    bio TEXT,
    connections_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create professional tags table
CREATE TABLE IF NOT EXISTS professional_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    professional_id UUID REFERENCES professionals(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create connections table for connection requests
CREATE TABLE IF NOT EXISTS connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending', -- pending, accepted, rejected
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(sender_id, receiver_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_professionals_location ON professionals(location);
CREATE INDEX IF NOT EXISTS idx_professionals_field ON professionals(field);
CREATE INDEX IF NOT EXISTS idx_professionals_user_id ON professionals(user_id);
CREATE INDEX IF NOT EXISTS idx_professional_tags_professional_id ON professional_tags(professional_id);
CREATE INDEX IF NOT EXISTS idx_connections_sender ON connections(sender_id);
CREATE INDEX IF NOT EXISTS idx_connections_receiver ON connections(receiver_id);
CREATE INDEX IF NOT EXISTS idx_connections_status ON connections(status);

-- Insert some demo professionals data
INSERT INTO professionals (full_name, profession, location, field, avatar_url, bio, connections_count) VALUES
('Sarah Williams', 'Full Stack Developer', 'Mumbai', 'Technology', 'https://i.pravatar.cc/150?img=10', 'Passionate about building scalable web applications', 245),
('Michael Chen', 'Product Designer', 'Bangalore', 'Design', 'https://i.pravatar.cc/150?img=11', 'Creating beautiful user experiences', 189),
('Priya Sharma', 'Marketing Manager', 'Delhi', 'Marketing', 'https://i.pravatar.cc/150?img=12', 'Digital marketing expert with 5+ years experience', 312),
('David Kumar', 'Data Scientist', 'Pune', 'Technology', 'https://i.pravatar.cc/150?img=13', 'ML and AI enthusiast', 156),
('Emma Johnson', 'Business Analyst', 'Mumbai', 'Finance', 'https://i.pravatar.cc/150?img=14', 'Helping businesses make data-driven decisions', 198),
('Raj Patel', 'Frontend Developer', 'Bangalore', 'Technology', 'https://i.pravatar.cc/150?img=15', 'React and Vue.js specialist', 267),
('Lisa Anderson', 'Content Writer', 'Delhi', 'Marketing', 'https://i.pravatar.cc/150?img=16', 'Crafting compelling stories for brands', 134),
('Arjun Singh', 'UX Researcher', 'Pune', 'Design', 'https://i.pravatar.cc/150?img=17', 'Understanding user behavior', 221);

-- Insert demo tags for professionals
INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['React', 'Node.js', 'Python']) AS tag WHERE full_name = 'Sarah Williams';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['UI/UX', 'Figma', 'Prototyping']) AS tag WHERE full_name = 'Michael Chen';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['Digital Marketing', 'SEO', 'Content']) AS tag WHERE full_name = 'Priya Sharma';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['ML', 'Python', 'Analytics']) AS tag WHERE full_name = 'David Kumar';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['Excel', 'SQL', 'Tableau']) AS tag WHERE full_name = 'Emma Johnson';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['React', 'Vue.js', 'TypeScript']) AS tag WHERE full_name = 'Raj Patel';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['Copywriting', 'SEO', 'Blogging']) AS tag WHERE full_name = 'Lisa Anderson';

INSERT INTO professional_tags (professional_id, tag) 
SELECT id, tag FROM professionals, unnest(ARRAY['User Research', 'Wireframing', 'Testing']) AS tag WHERE full_name = 'Arjun Singh';

-- Function to update connections count
CREATE OR REPLACE FUNCTION update_connections_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count + 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count + 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count - 1 
        WHERE user_id = NEW.sender_id OR user_id = NEW.receiver_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
        UPDATE professionals SET connections_count = connections_count - 1 
        WHERE user_id = OLD.sender_id OR user_id = OLD.receiver_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for connections count
CREATE TRIGGER trigger_update_connections_count
AFTER INSERT OR UPDATE OR DELETE ON connections
FOR EACH ROW
EXECUTE FUNCTION update_connections_count();
