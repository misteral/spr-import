# encoding: UTF-8

require 'csv'
require 'active_support'
#require 'action_controller'
#include ActionDispatch::TestProcess
#require 'yaml'
require 'russian'

# class AuditLogger < Logger
  # def format_message(severity, timestamp, progname, msg)
    # "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n" 
  # end 
# end

class ImportProducts
  
    def initialize()

#      #remove_products
#
#      #Images are below SPREE/vendor/import/productsXXXX/
#      # if there are more than one, take lexically last
#
    @dir = IMPORT_PRODUCT_SETTINGS[:file_path]
    #@product_ids = []
    #@products_before_import = Spree::Product.all
    #@names_of_products_before_import = []
    #@products_before_import.each do |product|
    #  @names_of_products_before_import << product.name
    #end
  end
  

  def create_permalink_url (product_name, product_sku)
    product_name = Russian.translit(product_name).downcase+"-"+product_sku
    #del_arr  = [",",'"',"~","!","@","%","^","(",")","<",">",":",";","{","}","[","]","&","`","„","‹","’","‘","“","”","•","›","«","´","»","°"]
    #del_arr.each {|n| product_name.delete! n }
    product_name.gsub!(/\s+/, '-').gsub!(/[^a-zA-Z0-9_]+/, '-')
    #product_name.gsub!(/ /,'-')
    url = product_name
  end

  def run

    #@products_before_import.each { |p| p.destroy }

    Dir.glob(File.join(@dir , '*.csv')).each do |file|
      puts "Importing file: " + file
      ActiveRecord::Base.transaction do
        load_file( file )
      end
    end
  end
  
  #If you want to write your own task or wrapper, this is the main entry point
  def load_file full_name
    rows = CSV.read( full_name ,  {:col_sep=>"\t",:quote_char=>"\t"} )

    if IMPORT_PRODUCT_SETTINGS[:first_row_is_headings]
              col = get_column_mappings(rows[0])
            else
              col = IMPORT_PRODUCT_SETTINGS[:column_mappings]
    end

    log("Importing products for #{full_name} began at #{Time.now}")
    #rows[IMPORT_PRODUCT_SETTINGS[:rows_to_skip]..-1].each do |row|
    rows[0..10].each do |row|
      log("Elements for import in file:" + rows.length)
      product_information = {}

      #Automatically map 'mapped' fields to a collection of product information.
      #NOTE: This code will deal better with the auto-mapping function - i.e. if there
      #are named columns in the spreadsheet that correspond to product
      # and variant field names.

      col.each do |key, value|
        #Trim whitespace off the beginning and end of row fields
        row[value].try :strip!
        product_information[key] = row[value]
      end

      #Manually set available_on if it is not already set
      product_information[:available_on] = Date.today - 1.day if product_information[:available_on].nil?
      product_information[:master_price] = product_information[:cost_price].to_f*product_information[:margin].to_f
      product_information[:permalink] = create_permalink_url(product_information[:name].clone, product_information[:sku])

      #log("#{pp product_information}")

      # распределение по моим таксонам
      #my_real_taxonomies = Spree::Taxon.select(:name).where("parent_id IS NOT NULL")

      for_suv_i_podarki =[
      "Куклы коллекционные от 30 см",#Сувениры > Интерьерные сувениры > Коллекционные куклы > Куклы коллекционные от 30 см
      'Коллекция "Элит"', #Сувениры > Предметы интерьера > Коллекция "Элит"
      "Хохлома",#Сувениры > Сувениры российских поставщиков > Народные промыслы > Хохлома
      "Бизнес-сувениры", #Сувениры > Бизнес-сувениры
      "Свечи и подсвечники", #Сувениры > Свечи и подсвечники
      "Наборы для суши и чайной церемонии"  #Сувениры > Посуда и кухонные принадлежности > Наборы для суши и чайной церемонии
       ]

      for_tov_detyam = [
      "Развивающие игрушки",#Игрушки > Обучающие и развивающие игры > Развивающие игрушки
      "Конструкторы",#Игрушки > Игрушки для мальчиков > Конструкторы
      "Детское творчество",#Игрушки > Детское творчество
      "Палатки и корзины для игрушек", #Игрушки > Товары для детей > Палатки и корзины для игрушек
      "Игрушки российского производства", #Игрушки > Игрушки российского производства
      "Товары для новорожденных" #Игрушки > Товары и игрушки для малышей > Товары для новорожденных
      ]

      fot_turizm = [
      "INTEX", #Сувениры > Летние товары > INTEX
      "Наборы для пикника",#Сувениры > Посуда и кухонные принадлежности > Наборы для пикника
      "Коврики", #Сувениры > Спорттовары, активный отдых > Туризм > Коврики
      "Мангалы, решетки", #Сувениры > Спорттовары, активный отдых > Туризм > Мангалы, решетки
      "Спальники", #Сувениры > Спорттовары, активный отдых > Туризм > Спальники
      "Столы, стулья, шезлонги", #Сувениры > Спорттовары, активный отдых > Туризм > Столы, стулья, шезлонги
      "Термосы и термокружки", #Сувениры > Спорттовары, активный отдых > Туризм > Термосы и термокружки
      "Гамаки", #Сувениры > Спорттовары, активный отдых > Туризм > Гамаки
      ]

      for_india = [
      "Сувениры из латуни",#Сувениры > Товары из Индии > Сувениры из латуни
      "Сувениры, игры из дерева" #Сувениры > Товары из Индии > Сувениры, игры из дерева
      ]
      skip = false




      variant_comparator_field = IMPORT_PRODUCT_SETTINGS[:variant_comparator_field].try :to_sym
      variant_comparator_column = col[variant_comparator_field]

      if IMPORT_PRODUCT_SETTINGS[:create_variants] and variant_comparator_column and
        p = Spree::Product.where(variant_comparator_field => row[variant_comparator_column]).first

        log("found product with this field #{variant_comparator_field}=#{row[variant_comparator_column]}")
        p.update_attribute(:deleted_at, nil) if p.deleted_at #Un-delete product if it is there
        p.variants.each { |variant| variant.update_attribute(:deleted_at, nil) }
        create_variant_for(p, :with => product_information)
      else
        next unless create_product_using(product_information)
      end
    end

    #if IMPORT_PRODUCT_SETTINGS[:destroy_original_products]
    #  @products_before_import.each { |p| p.destroy }
    #end
    log("Importing products for #{full_name} completed at #{DateTime.now}")
  end

  def create_product_using(params_hash)
    product = Spree::Product.new

    #The product is inclined to complain if we just dump all params
    # into the product (including images and taxonomies).
    # What this does is only assigns values to products if the product accepts that field.
    params_hash[:price] ||= params_hash[:master_price]
    params_hash.each do |field, value|
      if product.respond_to?("#{field}=")
        product.send("#{field}=", value)
      elsif property = Spree::Property.where(["name = ?", field]).first
        product.product_properties.build({:value => value, :property => property}, :without_protection => true)
      end
    end

    #after_product_built(product, params_hash)

    #We can't continue without a valid product here
    unless product.valid?
      log(msg = "A product could not be imported - here is the information we have:\n" +
          "#{pp params_hash}, #{product.errors.full_messages.join(', ')}")
      raise ProductError, msg
    end

    #Just log which product we're processing
    #log(product.name)

    #This should be caught by code in the main import code that checks whether to create
    #variants or not. Since that check can be turned off, however, we should double check.
    if @names_of_products_before_import.include? product.name
      log("#{product.name} is already in the system.\n")
    else
      #Save the object before creating asssociated objects
      product.save


      #Associate our new product with any taxonomies that we need to worry about
      IMPORT_PRODUCT_SETTINGS[:taxonomy_fields].each do |field|
        associate_product_with_taxon(product, field.to_s, params_hash[field.to_sym])
      end

      #Finally, attach any images that have been specified
      IMPORT_PRODUCT_SETTINGS[:image_fields].each do |field|
        find_and_attach_image_to(product, params_hash[field.to_sym])
      end

      if IMPORT_PRODUCT_SETTINGS[:multi_domain_importing] && product.respond_to?(:stores)
        begin
          store = Store.find(
            :first,
            :conditions => ["id = ? OR code = ?",
              params_hash[IMPORT_PRODUCT_SETTINGS[:store_field]],
              params_hash[IMPORT_PRODUCT_SETTINGS[:store_field]]
            ]
          )

          product.stores << store
        rescue
          log("#{product.name} could not be associated with a store. Ensure that Spree's multi_domain extension is installed and that fields are mapped to the CSV correctly.")
        end
      end

      #Log a success message

    end

    return true
  end



  ### IMAGE HELPERS ###

  # find_and_attach_image_to
  # This method attaches images to products. The images may come
  # from a local source (i.e. on disk), or they may be online (HTTP/HTTPS).
  def find_and_attach_image_to(product_or_variant, filename)
    return if filename.blank?

    #The image can be fetched from an HTTP or local source - either method returns a Tempfile
    file = filename =~ /\Ahttp[s]*:\/\// ? fetch_remote_image(filename) : fetch_local_image(filename)
    #An image has an attachment (the image file) and some object which 'views' it

    product_image = Spree::Image.new({:attachment => file,
                              :viewable_type => "Product",
                              :viewable_id => product_or_variant[:id],
                              :position => product_or_variant.images.length
                              })

    product_or_variant.images << product_image if product_image.save
  end

  def fetch_local_image(filename)
    filename = IMPORT_PRODUCT_SETTINGS[:product_image_path] + filename
    unless File.exists?(filename) && File.readable?(filename)
      log("Image #{filename} was not found on the server, so this image was not imported.", :warn)
      return nil
    else
      return File.open(filename, 'rb')
    end
  end


    #This method can be used when the filename matches the format of a URL.
    # It uses open-uri to fetch the file, returning a Tempfile object if it
    # is successful.
    # If it fails, it in the first instance logs the HTTP error (404, 500 etc)
    # If it fails altogether, it logs it and exits the method.
  def fetch_remote_image(filename)
    begin
      open(filename)
    rescue OpenURI::HTTPError => error
      log("Image #{filename} retrival returned #{error.message}, so this image was not imported")
    rescue
      log("Image #{filename} could not be downloaded, so was not imported.")
    end
  end

  ### TAXON HELPERS ###

  # associate_product_with_taxon
  # This method accepts three formats of taxon hierarchy strings which will
  # associate the given products with taxons:
  # 1. A string on it's own will will just find or create the taxon and
  # add the product to it. e.g. taxonomy = "Category", taxon_hierarchy = "Tools" will
  # add the product to the 'Tools' category.
  # 2. A item > item > item structured string will read this like a tree - allowing
  # a particular taxon to be picked out
  # 3. An item > item & item > item will work as above, but will associate multiple
  # taxons with that product. This form should also work with format 1.
  def associate_product_with_taxon(product, taxonomy, taxon_hierarchy)
    return if product.nil? || taxonomy.nil? || taxon_hierarchy.nil?
    #Using find_or_create_by_name is more elegant, but our magical params code automatically downcases
    # the taxonomy name, so unless we are using MySQL, this isn't going to work.
    taxonomy_name = taxonomy
    taxonomy = Spree::Taxonomy.find(:first, :conditions => ["lower(name) = ?", taxonomy])
    taxonomy = Spree::Taxonomy.create(:name => taxonomy_name.capitalize) if taxonomy.nil? && IMPORT_PRODUCT_SETTINGS[:create_missing_taxonomies]

    taxon_hierarchy.split(/\s*\&\s*/).each do |hierarchy|
      hierarchy = hierarchy.split(/\s*>\s*/)
      last_taxon = taxonomy.root
      hierarchy.each do |taxon|
        last_taxon = last_taxon.children.find_or_create_by_name_and_taxonomy_id(taxon, taxonomy.id)
      end

      #Spree only needs to know the most detailed taxonomy item
      product.taxons << last_taxon unless product.taxons.include?(last_taxon)
    end
  end
  ### END TAXON HELPERS ###

  #make sure there is an admin user
  def check_admin_user(password="spree123", email="spree@example.com")
      admin = User.find_by_login(email) ||  User.create(  :password => password,
														  :password_confirmation => password,
														  :email => email, 
														  :login => email  )
      # create an admin role and and assign the admin user to that role
      admin.roles << Role.find_or_create_by_name("admin")
      admin.save!
  end


  def log(message, severity = :info)
    @rake_log ||= ActiveSupport::BufferedLogger.new(IMPORT_PRODUCT_SETTINGS[:log_to])
    message = "[#{Time.now.to_s(:db)}] [#{severity.to_s.capitalize}] #{message}\n"
    @rake_log.send severity, message
    puts message
  end

end

#  def at_in( sym , row )
#    index = @header.index(@mapping.index(sym))
#    return nil unless index
#    return row[index]
#  end
#
#  #override if you have your categories encoded in one field or in any other way
#  def get_categories(row)
#    categories = []
#    cat = at_in(:category1 , row) if at_in(:category1 , row) # should invent some loop here
#    categories << cat if cat
#    cat = at_in(:category2 , row) if at_in(:category2 , row)# but we only support
#    categories << cat if cat
#    cat = at_in(:category3 , row) if at_in(:category3 , row)# three levels, so there you go
#    categories << cat if cat
#    categories
#  end
#
#  # TODO: For some reason this method seems to duplicate the categories
#  def set_taxon(product , row)
#    categories = get_categories(row)
#    if !categories.empty?
#
#      #puts "Categories #{categories.join('/')}"
#      #puts "Taxonomy #{@taxonomy} #{@taxonomy.name}"
#      @parent = @taxonomy.root  # the root of a taxonomy is a taxon , usually with the same name (?)
#                                #puts "Root #{parent} #{parent.id} #{parent.name}"
#      categories.each do |cat|
#        taxon = Taxon.find_by_name(cat)
#        unless taxon
#          puts "Creating -#{cat}-"
#          taxon = Taxon.create!(:name => cat , :taxonomy_id => @taxonomy.id , :parent_id => @parent.id )
#          #@audit_log.error "Creating taxon: #{cat}"
#        end
#        @parent = taxon
#        #puts "Taxon #{cat} #{parent} #{parent.id} #{parent.name}"
#      end
#
#      product.taxons.each do |t|
#        if t.name == @parent.name
#          puts "Taxons already set: #{@parent.name}"
#        else
#          product.taxons << @parent
#        end
#      end
#
#    else
#      #@audit_log.error "No category for SKU: #{at_in(:sku, row)} in row (#{row})"
#      puts "No category for SKU: #{at_in(:sku, row)} in row (#{row})"
#      return
#    end
#  end
#
#  def set_category(product , row)
#    category = Taxon.find_by_name(at_in(:category1, row))
#    if category
#      product_category = product.taxons.select {|t| t.parent.name == 'Categories' }.first.try(:name)
#
#      if product_category == category.name
#        puts "Category Already Set"
#      else
#        puts "Setting Category: #{category.name}"
#        product.taxons << category
#      end
#    else
#      puts "You need to create this category before trying to assign a product to it"
#      #@audit_log.error "Can't find category: #{brnd}"
#    end
#  end
#
#  def set_brand(product , row)
#    brand = Taxon.find_by_name(at_in(:brand, row))
#    if brand
#      product_brand = product.taxons.select {|t| t.parent.name == 'Brands' }.first.try(:name)
#
#      if product_brand == brand.name
#        puts "Brand Already Set"
#      else
#        puts "Setting Brand: #{brand.name}"
#        product.taxons << brand
#      end
#    else
#      puts "You need to create this brand before trying to assign a product to it"
#      #@audit_log.error "Can't find brand: #{brnd}"
#    end
#  end
#
#  # Set the shipping category by name
#  def set_shipping_category(product, row)
#    shipping_category = at_in(:shipping_category, row) if at_in(:shipping_category,row)
#    ship_category = ShippingCategory.find_by_name(shipping_category)
#    product.shipping_category = ship_category
#    #@audit_log.info "Set Shipping Category: #{product.sku} = #{ship_category.name}" if at_in(:shipping_category,row)
#    #@audit_log.warn "Set Shipping Category: #{product.sku} = NOT SET" if !at_in(:shipping_category,row)
#  end
#
#  # Set the shipping center by name
#  def set_shipping_center(product, row)
#    s_center = at_in(:shipping_center, row) if at_in(:shipping_center,row)
#    ship_center = ShipmentCenter.find_by_name(s_center)
#    product.shipment_center = ship_center
#    #@audit_log.info "Set Ship Centre: #{product.sku} = #{ship_center.name}" if at_in(:shipping_center,row)
#    #@audit_log.warn "Set Ship Centre: #{product.sku} = NOT SET" if !at_in(:shipping_center,row)
#  end
#
#  # Set the tax category by name
#  def set_tax_category(product, row)
#    tax_category = at_in(:tax_category, row) if at_in(:tax_category,row)
#    tax_cat = TaxCategory.find_by_name(tax_category)
#    product.tax_category = tax_cat
#    #@audit_log.info "Set Tax Category: #{product.sku} = #{tax_cat.name}" if at_in(:tax_category,row)
#    #@audit_log.warn "Set Tax Category: #{product.sku} = NOT SET" if !at_in(:tax_category,row)
#  end
#
#  # Get the product by sku
#  def get_product( row )
#    puts "get product row:" + row.join("--")
#    variant = Variant.find_by_sku( at_in(:sku , row ) )
#
#    prod = Product.find_by_name( at_in(:name , row ) )
#    puts variant
#
#    if !variant.nil?
#      puts "Found Variant by SKU: #{at_in(:sku,row)} "
#      variant.product
#    elsif !prod.nil?
#      puts "Found Product by Name: #{at_in(:name,row)} "
#      prod
#    else
#      puts "Creating new product harness."
#      p = Product.find_or_create_by_name(  :name => "sku" , :price => 5  , :sku => "sku")
#      p.save!
#      master = Variant.find_by_sku("sku")
#      master.product = Product.find_by_name("sku")
#      master.save
#      Product.find_by_name("sku")
#    end
#  end
#
#  # For testing
#  # Does not remove dependencies such as product properties etc.
#  def remove_products
#    check_admin_user
#    return unless remove_products?
#    while first = Product.first
#      first.delete
#    end
#    while first = Variant.first
#      first.delete
#    end
##    while first = Taxon.first
##      first.delete
##    end
#  end
#
#  #these are common attributes to product & variant (in fact prod delegates to master variant)
#  # so it will be called with either
#  def set_attributes_and_image( prod , row )
#
#    set_sku(prod,row)
#
#    if prod.class == Product
#      prod.name        = at_in(:name,row) if at_in(:name,row)
#      prod.description = at_in(:description, row) if at_in(:description, row)
#      set_prototype_properties(prod,row)
#      set_brand(prod,row) if at_in(:brand, row)
#      set_taxon(prod,row)
#      set_category(prod,row)
#      set_permalink(prod,row)
#      set_product_position(prod,row)
#      set_shipping_category(prod,row) if at_in(:shipping_category, row)
#      set_tax_category(prod,row) if at_in(:tax_category, row)
#      set_on_hand(prod,row)
#    end
#
#
#    # Add product and variations attributes
#    set_weight(prod,row)
#    set_dimensions(prod, row)
#    set_available(prod, row)
#
#    set_price(prod, row)
#    set_unit_price(prod, row)
#    add_image(prod, row)
#  end
#
#  # lots of little setters. if you need to override
#  def set_sku(prod,row)
#    prod.sku = at_in(:sku,row) if at_in(:sku,row)
#  end
#
#  def set_product_position(prod,row)
#    prod.position = at_in(:position,row) if at_in(:position,row)
#  end
#
#  def set_on_hand(prod,row)
#    prod.on_hand = at_in(:quantity,row) if at_in(:quantity,row)
#  end
#
#  # Mass delete or un-delete products (and variants)
#  def set_destroy(prod,row)
#    to_delete = at_in(:delete,row) if at_in(:delete,row)
#    if to_delete == "1"
#      puts "Deleting: #{prod}"
#      #@audit_log.info "Deleting product: #{prod}"
#      prod.deleted_at = Time.now()
#      prod.variants.each do |v|
#        v.deleted_at = Time.now()
#        v.save
#      end
#    elsif to_delete == "0"
#      puts "Un-deleting: #{prod}"
#      #@audit_log.info "Deleting product: #{prod}"
#      prod.deleted_at = nil
#      prod.variants.each do |v|
#        v.deleted_at = nil
#        v.save
#      end
#    end
#  end
#
#  # Set up product with a Prototype if :prototype field is available
#  def set_prototype_properties(prod,row)
#    prototype_id = at_in(:prototype,row) if at_in(:prototype,row)
#    if prototype = Prototype.find_by_name(prototype_id)
#      ##@audit_log.info "Setting Prototype: #{prototype.name}"
#      puts "Setting Prototype: #{prototype.name}"
#      prototype.properties.each do |property|
#        prod.product_properties.create(:property => property)
#      end
#      prod.option_types = prototype.option_types
#    else
#      puts "Prototype \"#{at_in(:prototype,row)}\" not found!"
#    end
#  end
#
#  ## Start setting product meta data ##
#
#  # ["meta_title", "meta_description", "meta_keywords"].each do |prop|
#  # define_method "set_#{prop}" do |prod,row|
#  # prod.send("#{prop}=",at_in(":#{prop}",row)) if at_in(":#{prop}",row)
#  # end
#  # end
#
#  def set_meta_title(prod,row)
#    prod.meta_title  = at_in(:meta_title,row) if at_in(:meta_title,row)
#  end
#
#  def set_meta_description(prod,row)
#    prod.meta_description  = at_in(:meta_description,row) if at_in(:meta_description,row)
#  end
#
#  def set_meta_keywords(prod,row)
#    prod.meta_keywords  = at_in(:meta_keywords,row) if at_in(:meta_keywords,row)
#  end
#
#  ## End of setting product meta data ##
#
#
#  def set_permalink(prod,row)
#    begin
#      perma = at_in(:permalink,row) if at_in(:permalink,row)
#      perma = prod.name.downcase.gsub(/\s+/, '-').gsub(/[^a-zA-Z0-9_]+/, '-') unless perma
#      #@audit_log.warn "Set Permalink: #{product.sku} = #{perma}" if at_in(:perma,row)
#      prod.permalink = perma if perma
#    rescue
#      puts "Error: Permalink already taken"
#      return
#    end
#
#  end
#
#  def set_weight(prod,row)
#    prod.weight = at_in(:weight,row) if at_in(:weight,row)
#  end
#
#  def set_available(prod,row)
#    prod.available_on = Time.now - 90000 unless prod.available_on # over a day, so to show immediately
#  end
#
#  def set_price(prod, row)
#    price = at_in(:web_price,row )
#    price = at_in(:price,row ) unless price
#    prod.price = price if price
#  end
#
#  def set_unit_price(prod, row)
#    cost_price = at_in(:unit_price, row)
#    prod.cost_price = cost_price if at_in(:unit_price,row)
#  end
#
#  def set_dimensions(prod, row)
#    prod.height = at_in(:height,row) if at_in(:height,row)
#    prod.width  = at_in(:width,row)  if at_in(:width,row)
#    prod.depth  = at_in(:depth,row)  if at_in(:depth,row)
#  end
#
#  def add_image(prod , row )
#    files = Array.new(3)
#    files << has_image(row)
#    files << has_image_two(row)
#    files << has_image_three(row)
#
#    for file_name in files
#
#      puts "File: #{file_name}"
#      #@audit_log.info "File: #{file_name}"
#      if file_name
#        if file_name && FileTest.exists?(file_name)
#          #@audit_log.info "Image/File name correct"
#        else
#          #@audit_log.error "Image/File mismatch: SKU(#{prod.sku}) - #{file_name} / #{file_name}"
#        end
#
#        type = file_name.split(".").last
#        i = Image.new(:attachment => fixture_file_upload(file_name, "image/#{type}" ))
#        i.viewable_type = "Product"
#        # link main image to the product
#        i.viewable = prod
#        prod.images << i
#
#        if prod.class == Variant
#          i = Image.new(:attachment => fixture_file_upload(file_name, "image/#{type}" ))
#          i.viewable_type = "Product"
#          prod.product.images << i
#        end
#      end
#    end
#  end
#
#  def has_image(row)
#    file_name = at_in(:image , row )
#
#    # if there is no file don't try to upload.
#    if file_name == nil
#      return false
#    end
#
#    file = find_file(file_name)
#    return file if file
#    return find_file(file_name + "")
#  end
#
#  def has_image_two(row)
#    file_name = at_in(:image2 , row )
#
#    # if there is no file don't try to upload.
#    if file_name == nil
#      return false
#    end
#
#    file = find_file(file_name)
#    return file if file
#    return find_file(file_name + "")
#  end
#
#  def has_image_three(row)
#    file_name = at_in(:image3 , row )
#
#    # if there is no file don't try to upload.
#    if file_name == nil
#      return false
#    end
#
#    file = find_file(file_name)
#    return file if file
#    return find_file(file_name + "")
#  end
#
#  # use (rename to has_image) to have the image name same as the sku
#  def has_image_sku(row)
#    sku = at_in(:sku,row)
#    return find_file( sku)
#  end
#
#  # recursively looks for the file_name you've given in you @dir directory
#  # if not found as is, will add .* to the end and look again
#  def find_file name
#    file = Dir::glob( File.join(@dir , "**", "*#{name}" ) ).first
#    return file if file
#    Dir::glob( File.join(@dir , "**", "*#{name}.*" ) ).first
#  end
#
#  def is_line_variant?(sku , index) #or file end
#                                    #puts "variant product -#{name}-"
#    return false if (index >= @data.length)
#    row = @data[index]
#    return false if row == nil
#    variant = at_in( :parent_sku, row )
#    return false if variant == nil
#    #puts "variant name -#{variant}-"
#    return false unless sku
#    #puts "variant return #{ name == variant[ 0 ,  name.length ] }"
#    return sku == variant[ 0 ,  sku.length ]
#  end
#
#  # read all variants of the product (using is_line_variant? above)
#  # uses the :option (mapped) attribute of the product row to find/create an OptionType
#  # and the same :option attribute to create OptionValues on the Variants
#  def slurp_variants(prod , index)
#    return index unless is_line_variant?(prod.sku , index )
#    #need an option type to create options, create dumy for now
#    prod_row = @data[index - 1]
#    option = at_in( :option , prod_row )
#    option = prod.name unless option
#    puts "Option type -#{option}-"
#    option_type  = OptionType.find_or_create_by_name_and_presentation(option , option)
#    product_option_type = ProductOptionType.new(:product => prod, :option_type => option_type)
#    product_option_type.save!
#    prod.reload
#    while is_line_variant?(prod.sku , index )
#      puts "variant slurp index " + index.to_s
#      row = @data[index]
#      option_value = at_in( :option , row )
#      option_value = at_in( :name , row ) unless option_value
#      puts "variant option -#{option_value}-"
#      option_value = OptionValue.create( :name         => option_value, :presentation => option_value,
#                                         :option_type  => option_type )
#      variant = Variant.create( :product => prod )  # create the new variant
#      variant.option_values << option_value         # add the option value
#      set_attributes_and_image( variant , row )     #set price and the other stuff
#      prod.variants << variant                      #add the variant (not sure if needed)
#      index += 1
#    end
#    return index
#  end

