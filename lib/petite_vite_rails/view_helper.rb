module PetiteVite
  module ViewHelper
    def vite_tags
      if Rails.env.development?
        port = PetiteVite.config.dev_server_port
        entrypoint_output = PetiteVite.config.entrypoint_output.sub(%r{^/+}, "")
        <<~SCRIPTS.html_safe
          <script type="module" src="http://localhost:#{port}/@vite/client"></script>
          <script type="module" src="http://localhost:#{port}/#{entrypoint_output}"></script>
        SCRIPTS
      else
        # https://vite.dev/guide/backend-integration.html
        #
        # <!-- 0. if production -->
        #
        # <!-- 1. for cssFile of manifest[name].css -->
        # <link rel="stylesheet" href="/{{ cssFile }}" />
        #
        # <!-- 2. for chunk of importedChunks(manifest, name) -->
        # <!-- 3. for cssFile of chunk.css -->
        # <link rel="stylesheet" href="/{{ cssFile }}" />
        #
        # <!-- 4 -->
        # <script type="module" src="/{{ manifest[name].file }}"></script>
        #
        # <!-- 5. for chunk of importedChunks(manifest, name) -->
        # <link rel="modulepreload" href="/{{ chunk.file }}" />

        out = []
        PetiteVite.config.manifest.contents.each do |_name, chunk|
          next if !chunk["isEntry"]
          # 1
          chunk["css"]&.each do |css|
            out.push(%(<link rel="stylesheet" href="/#{css}" />))
          end
          # 2
          chunk["dynamicImports"]&.each do |imported_name|
            # 3
            imported_chunk = PetiteVite.config.manifest.contents[imported_name]
            imported_chunk["css"]&.each do |css|
              out.push(%(<link rel="stylesheet" href="/#{css}" />))
            end
          end
          # 4
          out.push(%(<script type="module" src="/#{chunk.fetch("file")}"></script>))
          # 5
          chunk["dynamicImports"]&.each do |imported_name|
            imported_chunk = PetiteVite.config.manifest.contents[imported_name]
            out.push(%(<link rel="modulepreload" href="/#{imported_chunk.fetch("file")}" />))
          end
        end

        out.join("\n").html_safe
      end
    end
  end
end
