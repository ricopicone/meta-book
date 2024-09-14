import pdf2image
import tempfile
from pathlib import Path
import sys
import cv2
import numpy as np
from tqdm import tqdm

book_dir = Path(__file__).parent
book = book_dir / "machine-intelligence.pdf"
if len(sys.argv) > 2:
    book = sys.argv[1]

print(f"Reading file: {book}")

qrCodeDetector = cv2.QRCodeDetector()

total_wrong = 0
total_codes = 0

with tempfile.TemporaryDirectory() as image_dir:
    pages = pdf2image.convert_from_path(
        book, output_folder=image_dir, fmt="jpg", thread_count=4
    )
    for page, pil_image in enumerate(tqdm(pages)):
        image = np.array(pil_image)[:, :, ::-1].copy()
        detected, detections = qrCodeDetector.detectMulti(image)
        if detected:
            correct_side = "right" if page % 2 == 0 else "left"
            for i, detection in enumerate(detections):
                total_codes += 1
                side = (
                    "right" if detection[:, 0].mean() > image.shape[0] >> 1 else "left"
                )
                if side != correct_side:
                    total_wrong += 1
                    payload = qrCodeDetector.detectAndDecodeMulti(image)[1][i]
                    print(
                        f"QR Code on page {page+1} on the incorrect side (should be on the {correct_side} but is on the {side}). QR Code links to: {payload}"
                    )

print(f"{total_wrong} out of {total_codes} QR Codes on the wrong side.")
