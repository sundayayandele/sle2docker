module Sle2Docker
  # This class takes care of handling the native loadable images for
  # SUSE Linux Enterprise
  class NativeImage < Image
    IMAGES_DIR = '/usr/share/suse-docker-images/native'.freeze

    def self.list
      if File.exist?(NativeImage::IMAGES_DIR)
        Dir[File.join(NativeImage::IMAGES_DIR, '*.tar.xz')].map do |image|
          File.basename(image, '.tar.xz')
        end
      else
        []
      end
    end

    def initialize(image_name)
      @image_name = image_name
      compute_metadata_file
    end

    def activate
      verify_image

      puts 'Loading image'
      Docker::Image.load(File.join(IMAGES_DIR, "#{@image_name}.tar.xz"))
      image = Docker::Image.get(@image_id)
      image.tag('repo' => @repository, 'tag' => 'latest')
    end

    private

    def compute_metadata_file
      # example of image name and metadata file:
      # kiwi >= 8.30
      #      sles12sp3-container.x86_64-2.0.1-Build2.3.docker (image basename)
      #      sles12sp3-container.x86_64-2.0.1.metadata
      regexp = /(?<metadata_file>.*\d+\.\d+\.\d+)(-Build\d+\.\d+\.docker)?/x
      match = regexp.match(@image_name)
      match.nil? &&
        raise(DockerTagError,
              "Docker image #{@image_name} not found. \
               Run sle2docker list to check which docker images are available.")
      file = File.read(
        File.join(NativeImage::IMAGES_DIR, "#{match['metadata_file']}.metadata")
      )
      @metadata     = JSON.parse(file)
      @repository   = @metadata['image']['name']
      @tag          = @metadata['image']['tags'][0]
      @image_id     = "#{@repository}:#{@tag}"
    end
  end
end
