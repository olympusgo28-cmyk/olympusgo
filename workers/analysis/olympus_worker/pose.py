"""Finds where people's feet are. Faces and identity aren't looked at."""
import numpy as np

LEFT_ANKLE = 15
RIGHT_ANKLE = 16
MIN_SCORE = 0.5


class Pose:
    def __init__(self):
        # Here, so tests of everything else don't need the model.
        from rtmlib import Body

        self._model = Body(mode="balanced", backend="onnxruntime", device="cpu")

    def feet(self, image):
        """One (x, y) in pixels per person with an ankle in view."""
        keypoints, scores = self._model(image)
        return feet_from(keypoints, scores)


def feet_from(keypoints, scores):
    found = []
    if keypoints is None or len(keypoints) == 0:
        return found
    keypoints = np.asarray(keypoints)
    scores = np.asarray(scores)
    for person, confidence in zip(keypoints, scores):
        ankles = [person[i] for i in (LEFT_ANKLE, RIGHT_ANKLE) if confidence[i] >= MIN_SCORE]
        if ankles:
            x, y = np.mean(ankles, axis=0)
            found.append((float(x), float(y)))
    return found
