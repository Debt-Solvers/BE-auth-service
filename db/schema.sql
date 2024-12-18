-- Enable UUID extension for generating unique IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create USER table
CREATE TABLE IF NOT EXISTS "users" (
  user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  salt VARCHAR(50) NOT NULL,
  is_email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  reset_password_token VARCHAR(255),
  reset_password_expires TIMESTAMP WITH TIME ZONE,
  currency CHAR(3) DEFAULT 'CAD' NOT NULL CHECK (currency IN ('CAD', 'USD'))
);

-- Create AUTH_TOKEN table
CREATE TABLE IF NOT EXISTS auth_tokens (
  token_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "users"(user_id) ON DELETE CASCADE,
  token VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Modified schema: Keeping only `id` as the primary key
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES "users"(user_id) ON DELETE CASCADE, -- Allow null for default categories
  name VARCHAR(50) NOT NULL,
  description TEXT,
  color_code VARCHAR(7),
  is_default BOOLEAN DEFAULT FALSE, -- Indicates if the category is a default category
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Add a case-insensitive unique index for name and user_id if it doesn’t exist
DROP INDEX IF EXISTS unique_category_name_user;
CREATE UNIQUE INDEX IF NOT EXISTS unique_category_name_user ON categories (user_id, LOWER(name));

-- Create BUDGET table
CREATE TABLE IF NOT EXISTS budgets (
  budget_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "users"(user_id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) CHECK (amount >= 0) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE
);


-- Updated RECEIPT table with filehash
CREATE TABLE IF NOT EXISTS receipts (
  receipt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), -- Matches `ReceiptID` in the struct
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, -- Matches `UserID` in the struct
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE, -- New field for category_id, Matches `CategoryID` in the struct
  image BYTEA NOT NULL, -- Holds the actual image as binary data (BYTEA)  
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')), -- Matches `Status` in the struct with valid states
  total_amount DECIMAL(10, 2), -- Matches `TotalAmount` in the struct     
  merchant VARCHAR(255), -- Matches `Merchant` in the struct
  items JSONB, -- Matches `Items` in the struct
  scanned_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Matches `ScannedDate` in the struct
  transaction_date VARCHAR(50) NOT NULL, -- Matches `TransactionDate` in the struct
  transaction_time VARCHAR(50) NOT NULL, -- Matches `TransactionTime` in the struct
  tax DECIMAL(10, 2), -- Matches `Tax` in the struct
  discounts DECIMAL(10, 2), -- Matches `Discounts` in the struct
  file_hash VARCHAR(64) UNIQUE, -- Hash of the file content to detect duplicates (SHA-256 or similar)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Matches `CreatedAt` in the struct
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, -- Matches `UpdatedAt` in the struct
  deleted_at TIMESTAMP WITH TIME ZONE -- Soft delete support, optional
);


-- Create EXPENSE table
CREATE TABLE IF NOT EXISTS expenses (
  expense_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "users"(user_id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  amount DECIMAL(10, 2) CHECK (amount >= 0) NOT NULL,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  description TEXT,
  receipt_id UUID REFERENCES receipts(receipt_id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create USER_SETTINGS table with default currency set to CAD
CREATE TABLE IF NOT EXISTS user_settings (
  settings_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "users"(user_id) ON DELETE CASCADE,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  language_preference VARCHAR(10),
  theme_preference VARCHAR(20)
);

-- Create NOTIFICATION table
CREATE TABLE IF NOT EXISTS notifications (
  notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "users"(user_id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create AUDIT_LOG table to track changes in critical tables
CREATE TABLE IF NOT EXISTS audit_logs (
  log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID,
  table_name VARCHAR(50) NOT NULL,
  action VARCHAR(50) NOT NULL,
  old_data JSONB,
  new_data JSONB,
  change_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES "users"(user_id) ON DELETE SET NULL
);

-- Create indexes for frequently queried fields if they don’t exist
CREATE INDEX IF NOT EXISTS idx_expense_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expense_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_budget_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_category_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_scanned_date ON receipts (scanned_date);
CREATE INDEX IF NOT EXISTS idx_expenses_receipt_id ON expenses (receipt_id);

