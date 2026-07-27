import cv2
import numpy as np
import time
from datetime import datetime
from flask import Flask, Response

app = Flask(__name__)

def generate_frames():
    # Create a 640x480 dark grey canvas (simulating dark cabinet environment)
    width, height = 640, 480
    
    while True:
        frame = np.zeros((height, width, 3), dtype=np.uint8)
        frame[:] = (20, 20, 20)  # Dark background
        
        # Add grid lines
        for y in range(0, height, 40):
            cv2.line(frame, (0, y), (width, y), (35, 35, 35), 1)
        for x in range(0, width, 40):
            cv2.line(frame, (x, 0), (x, height), (35, 35, 35), 1)
            
        # OSD Camera Details
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, "CAM-01: RACK-SENSE INTERNAL", (20, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
        cv2.putText(frame, f"TIME: {now}", (20, 60),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        cv2.putText(frame, "STATUS: AC-1 RUNNING | AC-2 STANDBY", (20, 450),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)

        # Blinking REC dot
        if int(time.time()) % 2 == 0:
            cv2.circle(frame, (width - 30, 30), 8, (0, 0, 255), -1)

        _, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()
        
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
        time.sleep(0.05)

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, threaded=True)