-- ============================================
-- CloudStore Database Setup Script
-- ============================================
-- This file contains all SQL needed to set up the database
-- Run this in your Supabase SQL Editor if you need to recreate the schema

-- ============================================
-- 1. CREATE TABLES
-- ============================================

-- Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamptz DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  price numeric(10, 2) NOT NULL CHECK (price >= 0),
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  image_url text DEFAULT '',
  category text DEFAULT 'general',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  total_amount numeric(10, 2) NOT NULL CHECK (total_amount >= 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric(10, 2) NOT NULL CHECK (price >= 0),
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 2. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREATE RLS POLICIES
-- ============================================

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Products policies
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Public can view products"
  ON products FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "Admins can insert products"
  ON products FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete products"
  ON products FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Orders policies
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all orders"
  ON orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can update orders"
  ON orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Order items policies
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can create order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- ============================================
-- 4. CREATE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- ============================================
-- 5. CREATE TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for products table
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger for orders table
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. INSERT SAMPLE DATA
-- ============================================

INSERT INTO products (name, description, price, stock, category, image_url) VALUES
  (
    'Wireless Headphones',
    'High-quality Bluetooth headphones with noise cancellation',
    79.99,
    50,
    'electronics',
    'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg'
  ),
  (
    'Smart Watch',
    'Fitness tracker with heart rate monitor and GPS',
    199.99,
    30,
    'electronics',
    'https://images.pexels.com/photos/393047/pexels-photo-393047.jpeg'
  ),
  (
    'Laptop Backpack',
    'Durable backpack with padded laptop compartment',
    49.99,
    100,
    'accessories',
    'https://images.pexels.com/photos/2905238/pexels-photo-2905238.jpeg'
  ),
  (
    'USB-C Cable',
    'Fast charging USB-C cable, 6ft length',
    12.99,
    200,
    'accessories',
    'https://images.pexels.com/photos/4544530/pexels-photo-4544530.jpeg'
  ),
  (
    'Wireless Mouse',
    'Ergonomic wireless mouse with adjustable DPI',
    29.99,
    75,
    'electronics',
    'https://images.pexels.com/photos/2115257/pexels-photo-2115257.jpeg'
  ),
  (
    'Mechanical Keyboard',
    'RGB mechanical keyboard with blue switches',
    89.99,
    40,
    'electronics',
    'https://images.pexels.com/photos/1194713/pexels-photo-1194713.jpeg'
  ),
  (
    'Phone Stand',
    'Adjustable phone stand for desk',
    15.99,
    150,
    'accessories',
    'https://images.pexels.com/photos/4195325/pexels-photo-4195325.jpeg'
  ),
  (
    'Webcam HD',
    '1080p webcam with built-in microphone',
    59.99,
    60,
    'electronics',
    'https://images.pexels.com/photos/7504831/pexels-photo-7504831.jpeg'
  ),
  (
    'Portable Charger',
    '20000mAh portable power bank',
    39.99,
    80,
    'accessories',
    'https://images.pexels.com/photos/4792285/pexels-photo-4792285.jpeg'
  ),
  (
    'Bluetooth Speaker',
    'Waterproof Bluetooth speaker with 12-hour battery',
    45.99,
    90,
    'electronics',
    'https://images.pexels.com/photos/1279387/pexels-photo-1279387.jpeg'
  )
ON CONFLICT DO NOTHING;

-- ============================================
-- 7. MAKE A USER ADMIN (OPTIONAL)
-- ============================================
-- Replace 'your-email@example.com' with your actual email

-- UPDATE profiles
-- SET role = 'admin'
-- WHERE email = 'your-email@example.com';

-- ============================================
-- 8. VERIFY SETUP
-- ============================================

-- Check tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('profiles', 'products', 'orders', 'order_items');

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'products', 'orders', 'order_items');

-- Check policies
SELECT tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('profiles', 'products', 'orders', 'order_items');

-- Check sample products
SELECT COUNT(*) as product_count FROM products;

-- ============================================
-- NOTES
-- ============================================

/*
IMPORTANT SECURITY NOTES:
1. Never disable RLS on these tables
2. Always use auth.uid() in RLS policies
3. Test policies with different user roles
4. Keep admin role assignment manual (via SQL)

PERFORMANCE NOTES:
1. Indexes are created for frequently queried columns
2. Consider adding more indexes based on query patterns
3. Monitor slow queries in Supabase dashboard

MAINTENANCE:
1. Regularly backup your database
2. Monitor storage usage
3. Review and optimize queries
4. Update indexes as needed
*/
