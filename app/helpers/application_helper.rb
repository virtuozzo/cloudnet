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

  def remaining_balance(user)
    balance = user.account.remaining_balance
    balance < 0 ? "(#{pretty_total(balance)})" : "#{pretty_total(balance)}"
  end

  def payg_balance(user)
    balance = user.account.payment_receipts.to_a.sum(&:remaining_cost)
    balance < 0 ? "(#{pretty_total(balance)})" : "#{pretty_total(balance)}"
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
end
