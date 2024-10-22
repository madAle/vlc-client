require 'uri'

module VLC
  class Client
    module MediaControls
      # Expressions for parsing VLC's "status" command
      # @api private
      STATUS_MAPPING = {
        file: /\( new input: file:\/\/(.*) \)/,
        volume: /\( audio volume: (\d+) \)/,
        state: /\( state (.*) \)/ ,
      }.freeze

      def frame
        connection.write "frame"
      end

      # Plays media or resumes playback
      #
      # @overload play(media)
      #   addes the given media and plays it
      #
      #   @param media [String, File, URI] the media to be played
      #
      #   @example
      #     vlc.play('http://example.org/media.mp3')
      #
      # @overload play
      #   plays the current media or resume playback is paused
      #
      #   @example
      #     vlc.play('http://example.org/media.mp3')
      #     vlc.pause
      #     vlc.play #resume playback
      #
      def play(media = nil)
        connection.write(media.nil? ? "play" : "add #{media(media)}")
      end

      # Pauses playback
      def pause
        connection.write("pause")
      end

      # Seek in seconds
      def seek(seconds = 0)
        connection.write("seek #{seconds.to_i}")
      end

      # Stops media currently playing
      def stop
        connection.write("stop")
      end

      # Gets the title of the media at play
      def title
        connection.write("get_title", false)
      end

      # Gets the current playback progress in time
      #
      # @return [Integer] time in seconds
      #
      def time
        Integer(connection.write("get_time", false))
      rescue ArgumentError
        0
      end

      # Gets the length of the media being played
      #
      # @return [Integer] time in seconds
      #
      def length
        Integer(connection.write("get_length", false))
      rescue ArgumentError
        0
      end

      # Get the progress of the the media being played
      #
      # @return [Integer] a relative value on percentage
      #
      def progress
        l = length
        l.zero? ? 0 : 100 * time / l
      end

      # Queries VLC if media is being played
      def playing?
        connection.write("is_playing", false) == "1"
      end

      # Queries VLC if playback is currently stopped
      def stopped?
        connection.write("is_playing", false) == "0"
      end

      # Queries/Sets VLC volume level
      #
      # @overload volume()
      #
      #   @return [Integer] the current volume level
      #
      # @overload volume(level)
      #
      #   @param [Integer] level the volume level to set
      #
      def volume(level = nil)
        return Integer(connection.write("volume", false)) if level.nil?
        connection.write("volume #{Integer(level)}")
      rescue ArgumentError
        level.nil? ? 0 : nil
      end

      # @see #volume
      def volume=(level)
        volume(level)
      end

      # @return [Hash{Symbol => String}] the mapping of status strings
      # @example
      #  status = vlc.status
      #  status[:file] # => "/path/to/file/playing.mp3"
      #  status[:volume] # => "256"
      #  status[:state] # => "playing"
      def status
        connection.write("status")
        raw_status = 3.times.collect { connection.read }

        STATUS_MAPPING.keys.zip(raw_status).map do |k, s|
          [k, STATUS_MAPPING[k].match(s)[1]]
        end.to_h
      end
    end
  end
end
