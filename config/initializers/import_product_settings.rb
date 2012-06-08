# This file is the thing you have to config to match your application

IMPORT_PRODUCT_SETTINGS = {
  :column_mappings => { #Change these for manual mapping of product fields to the CSV file
    #:id => 0,
    #:parent_id => 1,
    :sku => 0,
    :name => 3,
    #:master_price => 14,
    :margin => 5,
    :cost_price => 4,
    #:weight => 4,
    #:height => 4,
    #:width => 4,
    #:depth => 4,
    :image_main => 2,
    #:image_2 => 4,
    #:image_3 => 4,
    #:image_4 => 4,
    :description => 1,
    #:order_min => 12,
    #:order_step => 4,
    :category => 6
  },
  :create_missing_taxonomies => true,
  :file_path => "/home/ror/import_spree/",
  :taxonomy_fields => [:category], #Fields that should automatically be parsed for taxons to associate
  :image_fields => [:image_main], #Image fields that should be parsed for image locations
  #:product_image_path => "#{Rails.root}/lib/etc/product_data/product-images/", #The location of images on disk
  :product_image_path => "", #The location of images on disk
  :rows_to_skip => 0, #If your CSV file will have headers, this field changes how many rows the reader will skip
  :log_to => File.join(Rails.root, '/log/', "import_products_#{Rails.env}.log"), #Where to log to
  :destroy_original_products => false, #Delete the products originally in the database after the import?
  :first_row_is_headings => false, #Reads column names from first row if set to true.
  :create_variants => false, #Compares products and creates a variant if that product already exists.
  :variant_comparator_field => :sku, #Which product field to detect duplicates on
  :multi_domain_importing => false, #If Spree's multi_domain extension is installed, associates products with store
  :store_field => :store_code #Which field of the column mappings contains either the store id or store code?
}

