require 'spec_helper_acceptance'

describe 'azure_vm' do
  def test_get_vm(name)
    azureHelper = AzureHelper.new
    vm = azureHelper.get_virtual_machine(name)
    expect(vm).not_to be_nil
    expect(vm.first.name).to eq(name)
    vm.first
  end

  def test_get_image(name)
    azureHelper = AzureHelper.new
    image = azureHelper.get_image(name)
    expect(image).not_to be_nil
    expect(image.first.name).to eq(name)
    image.first
  end

  def test_get_images()
    azureHelper = AzureHelper.new
    images = azureHelper.get_all_images()
    expect(images).not_to be_nil
    expect(images.size).not_to eq(0)
    images
  end

  describe 'find a specfic image in azure' do
    it 'find an image in azure' do
      images = test_get_images()
      image = test_get_image(images.first.name)
      expect(images.first.name).to eq(image.name)
    end
  end
end
