class Fetcher

  PRODUCT_TYPES = {
    kimchi_refrigerator: 'http://www.elandappliance.com/_CGI/SEARCH3.HTML?MAJOR=REF&MINOR_SORT=REF:KIMREF&NUM_RESULTS=100',
    rice_cooker: 'http://www.elandappliance.com/_CGI/SEARCH3.HTML?MAJOR=SMALL&PRICE=2&MINOR_SORT=SMALL:RICE&NUM_RESULTS=100',
    onsu_mat: 'http://www.elandappliance.com/_CGI/SEARCH3?PN=ONSU&NUM_RESULTS=100'
  }

  def initialize
    @items = Hash.new { |h, k| h[k] = [] }
  end

  def fetch!
    PRODUCT_TYPES.each do |type, results_url|
        results_doc = Nokogiri::HTML(RestClient.get(results_url).to_s)
        results_doc.css('.cat_grid_product').each { |node| @items[type] << node }
    end
  end

  def to_feed
    Nokogiri::XML::Builder.new do |xml|
      xml.rss(version: '2.0', 'xmlns:g' => 'http://base.google.com/ns/1.0') {
        xml.channel {
          xml.title 'eLand Appliances Google Shopping Feed'
          xml.link 'http://www.elandappliance.com/'
          xml.description 'RSS feed for Google Shopping'
          @items.each do |type, list|
            list.each do |item_node|
              product = Product.new(item_node, type)
              product.append_to(xml)
            end
          end
        }
      }
    end.to_xml
  end

end

class Product

  HOST = 'www.elandappliance.com'

  ATTRIBUTES = [
    :id,
    :title,
    :description,
    :link,
    :condition,
    :price,
    :availability,
    :image_link,
    :gtin,
    :mpn,
    :brand,
    :google_product_category,
    :product_type,
    :shipping
  ]

  GOOGLE_PRODUCT_CATEGORIES = {
   kimchi_refrigerator: 'Home & Garden > Kitchen & Dining > Kitchen Appliances > Refrigerators',
   rice_cooker: 'Home & Garden > Kitchen & Dining > Kitchen Appliances > Food Cookers & Steamers > Rice Cookers',
   onsu_mat: 'Home & Garden > Linens & Bedding > Bedding > Quilts & Comforters'
  }

  PRODUCT_TYPES = {
    kimchi_refrigerator: 'Appliances > Refrigerators',
    rice_cooker: 'Appliances > Rice Cooker',
    onsu_mat: 'Appliances > Hot Water Mat'
  }

  def initialize(node, type)
    @node, @type = node, type
  end

  def append_to(xml)
    xml.item {
      ATTRIBUTES.each do |attribute|
        xml['g'].send(attribute, self.send(attribute) || 'not yet implemented')
      end
    }
  end

  def id
    @node.css('.header_product_model').first.children.last.to_s.gsub("\u00A0", "")
  end

  def title
    split(@node.css('.header_product_desc').text).first.strip
  end

  def description
    split(@node.css('.header_product_desc').text).last.strip
  end

  def link
    path = @node.css('.cat_grid_product_img').first.attributes['href'].value
    URI::HTTP.build(host: HOST, path: path).to_s
  end

  def condition
    'new'
  end

  def price
    @node.css('.product_final_total').first.text.strip
  end

  def availability
    'in stock'
  end

  def image_link
    source = @node.css('.cat_grid_product_img img').first.attributes['src'].value
    URI::HTTP.build(host: HOST, path: source.split("?").first)
  end

  def gtin
    " "
  end

  def mpn
    id
  end

  def brand
    @node.css('.cat_grid_brand_name').text.strip
  end

  def google_product_category
    GOOGLE_PRODUCT_CATEGORIES[@type]
  end

  def product_type
    PRODUCT_TYPES[@type]
  end

  def shipping
    'US:::0 USD'
  end

  def split(string)
    out = string.split("|")
    if out.length < 2
      out = string.split(" l ")
    end
    out
  end

end