# encoding: utf-8

module FeatureHelpers
  def basket_with_order_create
    basket_create
    visit basket_path
    order_create
  end

  def basket_create
    visit root_path
    click_link 'Create New Basket'

    expect(page).to have_content('Pizza Lieferservice und Pizzaservice')

    plz = '12347'

    # This code fails very often in CI. Instead of testing pizza.de UI
    # we simply hope for the best and visit the shop-list page for the
    # given postal code directly.
    #~　plzort = plz + ' Berlin'
    #~　fill_in 'plzsearch_input', with: plz
    #~　expect(page).to have_content(plzort)
    #~　first('.suggest_entry_active, .suggest_entry').click

    visit root_path + '/' + plz

    expect(page).to have_content('pizza.de-Bewertungen in PLZ 12347 Britz')
    click_link 'Indian Curry'

    # wait for page load, reduce breakage
    expect(page).to have_content('Warenkorb')
    within('#hipsterTopBar') do
      click_on 'Choose Indian Curry'
    end

    expect(page).to have_content('Share Link')
  end

  def order_create
    click_on 'Place New Order'
    click_on 'Chicken Curry', match: :first

    accept_nick!

    click_on 'Place My Order in Group Basket'

    expect(page).to have_content 'You still need to pay'
    expect(page).to have_content 'Chicken Curry'
    expect(page).to have_content 'Tėst Ñiçk 1_2-3'
  end

  def accept_nick!
    page.driver.js_prompt_input = "Tėst Ñiçk 1_2-3"
    page.driver.accept_js_prompts!
  end

  def reload
    visit(current_url)
  end

  def shot(name)
    path = "tmp/capybara/manual_screenshot_#{name}.png"
    save_screenshot(path)
    puts
    puts "IMAGE = #{path}"
    puts "URL   = #{Capybara.current_url}"
    puts
  end

  def print_console_msgs
    page.driver.console_messages.each { |m| puts m[:message] }
  end

  def visit_basket_as_new_user
    visit basket_path
    expect(page).not_to have_css('div.flash')

    url = Capybara.current_url
    Capybara.reset_sessions!
    visit url
    expect(page).not_to have_css('div.flash')
  end

  def wait_until_content(c)
    15.times do
      # rescue to silence NodeNotAttachedError exceptions. Required when
      # HipsterPizza’s replay mode modifies the page concurrently to
      # when Capybara tries to check for text content. Since we don’t
      # care about the intermediate pages, we can treat these errors as
      # if the content wasn’t present.
      return if (has_content?(c) rescue nil)
    end
    expect(page).to have_content(c)
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
