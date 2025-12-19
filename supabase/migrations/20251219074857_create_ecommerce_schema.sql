/*
  # E-Commerce Database Schema

  ## Overview
  Complete database schema for a cloud-based e-commerce application with user authentication,
  product management, shopping cart, and order processing.

  ## Tables Created

  ### 1. profiles
  Extends Supabase auth.users with additional user information
  - `id` (uuid, references auth.users): User ID
  - `email` (text): User email
  - `full_name` (text): User's full name
  - `role` (text): User role (user/admin), defaults to 'user'
  - `created_at` (timestamptz): Account creation timestamp

  ### 2. products
  Store product catalog information
  - `id` (uuid): Product ID
  - `name` (text): Product name
  - `description` (text): Product description
  - `price` (numeric): Product price
  - `stock` (integer): Available stock quantity
  - `image_url` (text): Product image URL
  - `category` (text): Product category
  - `created_at` (timestamptz): Creation timestamp
  - `updated_at` (timestamptz): Last update timestamp

  ### 3. orders
  Store customer orders
  - `id` (uuid): Order ID
  - `user_id` (uuid): Reference to user who placed order
  - `total_amount` (numeric): Total order amount
  - `status` (text): Order status (pending/processing/shipped/delivered/cancelled)
  - `created_at` (timestamptz): Order creation timestamp
  - `updated_at` (timestamptz): Last update timestamp

  ### 4. order_items
  Store individual items within each order
  - `id` (uuid): Order item ID
  - `order_id` (uuid): Reference to order
  - `product_id` (uuid): Reference to product
  - `quantity` (integer): Quantity ordered
  - `price` (numeric): Price at time of order
  - `created_at` (timestamptz): Creation timestamp

  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Users can only view/edit their own data
  - Admin role can manage all data
  - Public can view products (read-only)

  ## Important Notes
  1. Passwords are handled by Supabase Auth (bcrypt hashed automatically)
  2. JWT tokens are managed by Supabase Auth
  3. First user registered should be made admin manually or via SQL
  4. Product stock is decreased when orders are placed
*/

-- Create profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamptz DEFAULT now()
);

-- Create products table
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

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  total_amount numeric(10, 2) NOT NULL CHECK (total_amount >= 0),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric(10, 2) NOT NULL CHECK (price >= 0),
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

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

-- Products policies (public read, admin write)
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

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert sample products for demonstration
INSERT INTO products (name, description, price, stock, category, image_url) VALUES
  ('Wireless Headphones', 'High-quality Bluetooth headphones with noise cancellation', 79.99, 50, 'electronics', 'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg'),
  ('Smart Watch', 'Fitness tracker with heart rate monitor and GPS', 199.99, 30, 'electronics', 'https://images.pexels.com/photos/393047/pexels-photo-393047.jpeg'),
  ('Laptop Backpack', 'Durable backpack with padded laptop compartment', 49.99, 100, 'accessories', 'https://images.pexels.com/photos/2905238/pexels-photo-2905238.jpeg'),
  ('USB-C Cable', 'Fast charging USB-C cable, 6ft length', 12.99, 200, 'accessories', 'https://images.pexels.com/photos/4544530/pexels-photo-4544530.jpeg'),
  ('Wireless Mouse', 'Ergonomic wireless mouse with adjustable DPI', 29.99, 75, 'electronics', 'https://images.pexels.com/photos/2115257/pexels-photo-2115257.jpeg'),
  ('Mechanical Keyboard', 'RGB mechanical keyboard with blue switches', 89.99, 40, 'electronics', 'https://images.pexels.com/photos/1194713/pexels-photo-1194713.jpeg'),
  ('Phone Stand', 'Adjustable phone stand for desk', 15.99, 150, 'accessories', 'https://images.pexels.com/photos/4195325/pexels-photo-4195325.jpeg'),
  ('Webcam HD', '1080p webcam with built-in microphone', 59.99, 60, 'electronics', 'https://images.pexels.com/photos/7504831/pexels-photo-7504831.jpeg'),
  ('Portable Charger', '20000mAh portable power bank', 39.99, 80, 'accessories', 'https://images.pexels.com/photos/4792285/pexels-photo-4792285.jpeg'),
  ('Bluetooth Speaker', 'Waterproof Bluetooth speaker with 12-hour battery', 45.99, 90, 'electronics', 'https://images.pexels.com/photos/1279387/pexels-photo-1279387.jpeg')
ON CONFLICT DO NOTHING;
