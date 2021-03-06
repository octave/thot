class Admin < ActiveRecord::Base

  # https://github.com/ryanb/cancan/wiki/Role-Based-Authorization
  ROLES = %w[operator admin]

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  devise :database_authenticatable, :recoverable

  # # Setup accessible (or protected) attributes for your model
  # attr_accessible :name, :email, :role, :password, :password_confirmation, :remember_me, :lab_ids
  # # attr_accessible :title, :body

  has_and_belongs_to_many :labs, :class_name => "Lab", :join_table => "operatorships"
  has_many :inventory_sessions, -> {order 'updated_at DESC'}, :class_name => "InventorySession", :foreign_key => "admin_id"
  has_many :users, :through => :labs

  def operates?(o)
    case o.class.name
    when "Lab"
      ! self.labs.find_by_id(o.id).nil?
    when "Fixnum"
      ! self.labs.find_by_id(o).nil?
    when "User"
      l=o.lab
      l.nil? ? false : (! self.labs.find_by_id(l.id).nil?)
    else
      false
    end
  end

  def available_labs
    if admin?
      Lab.order('nick ASC').all
    else
      labs.order('nick ASC').all
    end
  end

  def role?(base_role)
    ROLES.index(base_role.to_s) <= ROLES.index(role)
  end

  def admin?
    self.role == "admin"
  end

  def locations
    self.labs.map{|l| l.locations}.flatten!.uniq
  end

  def send_welcome_email
    generate_reset_password_token!
    AdminMailer.welcome_email(self).deliver
  end
end
