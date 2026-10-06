class ServiceResult
  attr_reader :data, :error   # it allows external code to read these values directly 

  def self.success(data = nil)
    new(success: true, data: data)
  end

  def self.error(error)
    new(success: false, error: error)
  end

  def initialize(success:, data: nil, error: nil)
    @success = success
    @data = data
    @error = error
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
