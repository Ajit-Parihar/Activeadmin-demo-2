ActiveAdmin.register Order do
  permit_params :user_id, :product_id, :seller_id, :business_id

  if proc { current_admin_user.admin? || current_admin_user.seller? }
    actions :index, :show
  else
    actions :show
  end

  controller do
    def index
      unless current_admin_user.admin? || current_admin_user.seller?
        order = Order.find_by(user_id: current_admin_user.id)

        unless order == nil
        redirect_to admin_order_path(order.id)
        else
          redirect_to admin_root_path, alert: "You have not purchased anything on this platform."
        end
      else
        super
      end
    end

    def scoped_collection
      if current_admin_user.admin?
        Order.where(id: Order.select("MIN(id)").group(:product_id))
      elsif current_admin_user.seller?
        seller_orders = Order.where(seller_id: current_admin_user.id)
        Order.where(id: seller_orders.select("MIN(id)").group(:product_id))
      else
          Order.where(user_id: current_admin_user.id).group(:product_id)
      end
    end
  end
  
  index do
    selectable_column
      column "Product Name" do |order|
        order.product&.name
      end

      column "Product Price" do |order|
      number_to_currency(order.product&.price, unit: "₹", precision: 0)
    end
    actions
  end

  show do
     if current_admin_user.admin?
      order_id = Order.find(params[:id])
      all_orders = Order.where(product_id: order_id.product_id)

      panel "Total buyers have purchased this product" do
        table_for all_orders do
          column "Buyer" do |order|
            order.user.first_name
          end
          column "Ordered At" do |order|
            order.created_at.strftime("%B %d, %Y %H:%M")
          end
          column "Seller" do |order|
            order.seller.first_name
          end
          column "Product" do |order|
            image_tag(order.product.image, style: "max-width: 300px;", class: "product-thumb", onclick: "highlightImage(this)")
         end
        end
      end
     elsif current_admin_user.seller?
      all_orders = Order.where(seller_id: current_admin_user.id)
      panel "Total buyers have purchased this product" do
        table_for all_orders do
          column "Name" do |order|
            order.user.first_name+" "+order.user.last_name
          end
          column "User" do |order|
            order.user.email
          end
          column "Ordered At" do |order|
            order.created_at.strftime("%B %d, %Y %H:%M")
          end
          column "Product" do |order|
              image_tag(order.product.image, style: "max-width: 300px;", class: "product-thumb", onclick: "highlightImage(this)")
          end
        end
      end
     else

      all_orders = Order.where(user_id: current_admin_user.id)
      panel "Total buyers have purchased this product" do
        table_for all_orders do
          column "product" do |order|
             image_tag(order.product.image,  class: "product-thumb",)
          end
          column "Buyer" do |order|
            order.user.first_name
          end
          column "Ordered At" do |order|
            order.created_at.strftime("%B %d, %Y %H:%M")
          end
          column "Seller" do |order|
            order.seller.first_name
          end

          column "deliver status" do |order|
               order.status_type
          end

          column "Rating" do |order|
            rating = Rating.find_by(order_id: order.id)
          
            if rating.nil? && order.status_type == "delivered"
              link_to "Add Rating", "#", onclick: "productRating(this)", class: "button primary", data: { id: order.id }
            elsif rating.present?
              rating.rate
            else
              "Not Rated Yet"
            end
          end
          
          column "Cancel Order" do |order|
            unless order.status_type == "delivered" || order.status_type == "cancelled"
              link_to "Cancel", cancel_order_admin_order_path(order), 
              method: :post, 
              data: { confirm: "Are you sure?" }, 
              class: "button primary"
              else         
              link_to "Cancel", "#", class: "button primary", style: "opacity: 0.5;"
            end
          end
          column "Details" do |order|
            span link_to "Check Order", admin_ordertracker_path(order_id: order.id), class: "button"
          end
        end
        
      end
     end
  end
  
  member_action :cancel_order, method: :post do
      # order = Order.find(params[:id])
      puts "resoruce put "
      puts resource.inspect
      resource.update(status_type: "cancelled")
      redirect_to admin_order_path(resource.id), notice: "Order Cancel Succssfully"
  end
end
