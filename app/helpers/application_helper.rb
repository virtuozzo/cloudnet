module ApplicationHelper
  def title(title)
    content_for :title, title.to_s
  end

  def markdown(content, linebreaks = true)
    options = {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true
    }

    renderer = Redcarpet::Render::HTML.new(filter_html: true, no_images: true, prettify: true)
    output = Redcarpet::Markdown.new(renderer, options).render(content).html_safe

    linebreaks ? preserve(output) : output
  end

  def navigation_link(controllers, text, target)
    @link = { active: controllers.include?(params[:controller]), target: target, text: text }
    render partial: 'shared/nav_item',  locals: { link: @link }
  end

  def menu_header
    if user_signed_in?
      render partial: 'shared/menu/logged_header'
    else
      render partial: 'shared/menu/public_header'
    end
  end

  def gravatar_image(user, size = 32)
    hash = Digest::MD5.hexdigest(user.email.downcase.strip)
    "https://secure.gravatar.com/avatar/#{hash}?s=#{size}&d=retro"
  end

  def pretty_total(total, unit = '$', precision = 2)
    Invoice.pretty_total(total, unit, precision)
  end

  # Pending invoice amount (-) wallet balance
  def remaining_balance(user)
    balance = pretty_total user.account.remaining_balance
    # remaining_balance() is confusing, in the codebase negative values mean credit, but for users
    # we represent negative balances as being in debt.
    balance.gsub!('-', '')
    remaining_balance_in_credit?(user) ? "#{balance}" : "-#{balance}"
  end
  
  def current_user_remaining_balance
    Rails.cache.fetch(['remaining_balance', current_user.id], expires_in: 1.hour) do
      remaining_balance(current_user)
    end
  end

  def remaining_balance_in_credit?(user)
    user.account.remaining_balance <= 0
  end
  
  def topup_balance(balance)
    current_balance = pretty_total balance
    current_balance.gsub!('-', '')
    balance <= 0 ? "#{current_balance}" : "-#{current_balance}"
  end

  def tag_string(tag)
    tag.to_s.gsub(/_/, ' ').capitalize
  end

  def haml_tag_if(condition, *args, &block)
    if condition
      haml_tag *args, &block
    else
      yield
    end
  end

  def flash_class(flash_type)
    case flash_type
      when :success
        'alert-success'
      when :error
        'alert-danger'
      when :alert
        'alert-warning'
      when :notice
        'alert-info'
      else
        flash_type.to_s
    end
  end

  def gb_to_tb(value)
    if value >= 1000
      "#{value / 1000.0} TB"
    else
      "#{value} GB"
    end
  end

  def minify_js_partial(file)
    contents = render(partial: file)
    return contents.html_safe if development?
    Uglifier.new.compile(contents).html_safe
  end

  def development?
    Rails.env.development?
  end
  
  def body_class
    controller_name + ' ' + controller_name + '-' + action_name
  end
  
  def provisioner_role_options(selected)
    options_for_select(Server.provisioner_roles.map {|role| [role.humanize, role]}, selected)
  end
  
  # sliders when
  # no vps AND no package choosen AND values in url params
  def activate_slider_tab
    @wizard_object.location && (!@wizard_object.location.budget_vps and !@wizard_object.package_matched and @wizard_object.params_values?)
  end
  
  def boolean_to_words(value)
    value ? "Yes" : "No"
  end
  
  def boolean_to_results(value)
    value ? "Pass" : "Fail"
  end
  
  def just_logged_out?
    params[:logout] == "1"
  end
  
end
