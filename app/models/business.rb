class Business < ApplicationRecord
    belongs_to :seller, class_name: "AdminUser" 
    has_many :products
    has_many :orders
end
