require 'test_helper'

class Admin::PlansControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create(:account, admin: true)
    @regular_user = create(:account, admin: false)
    @plan = create(:plan)
  end

  test 'admin can view plans index' do
    login_as(@admin)
    get admin_plans_path
    assert_response :success
  end

  test 'admin can view plan details' do
    login_as(@admin)
    get admin_plan_path(@plan)
    assert_response :success
  end

  test 'admin can grandfather plan' do
    login_as(@admin)
    post grandfather_admin_plan_path(@plan)
    assert_redirected_to admin_plan_path(@plan)
    assert_not @plan.reload.public
  end

  test 'non-admin cannot access plans index' do
    login_as(@regular_user)
    get admin_plans_path
    assert_redirected_to root_path
  end

  test 'non-admin cannot grandfather plans' do
    login_as(@regular_user)
    post grandfather_admin_plan_path(@plan)
    assert_redirected_to root_path
  end
end
