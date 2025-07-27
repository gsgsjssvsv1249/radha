from waifu import Waifu

def main():
    waifu = Waifu()

    try:
        waifu.initialise(
            user_input_service='whisper',  # Change to 'console' if mic fails
            chatbot_service='openai',
            tts_service='elevenlabs',
            output_device=8
        )
    except OSError:
        print("⚠️ No microphone available — switching to console input")
        waifu.initialise(
            user_input_service='console',
            chatbot_service='openai',
            tts_service='elevenlabs',
            output_device=8
        )

    while True:
        waifu.conversation_cycle()

if __name__ == "__main__":
    main()
