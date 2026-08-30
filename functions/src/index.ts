import { HttpsError, onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const routesApiKey = defineSecret("GOOGLE_ROUTES_API_KEY");

type Point = { latitude: number; longitude: number };

function readPoint(value: unknown, label: string): Point {
  const point = value as Partial<Point> | undefined;
  const latitude = point?.latitude;
  const longitude = point?.longitude;
  if (
    typeof latitude !== "number" ||
    typeof longitude !== "number" ||
    latitude < -90 || latitude > 90 ||
    longitude < -180 || longitude > 180
  ) {
    throw new HttpsError("invalid-argument", `${label} coordinates are invalid.`);
  }
  return { latitude, longitude };
}

function durationToSeconds(value: unknown): number {
  const match = typeof value === "string" ? /^(\d+(?:\.\d+)?)s$/.exec(value) : null;
  if (!match) throw new HttpsError("internal", "Route duration is unavailable.");
  return Math.round(Number(match[1]));
}

export const computeTripRoute = onCall(
  {
    region: "asia-southeast1",
    secrets: [routesApiKey],
  },
  async (request) => {
    const origin = readPoint(request.data?.origin, "Origin");
    const destination = readPoint(request.data?.destination, "Destination");
    const response = await fetch(
      "https://routes.googleapis.com/directions/v2:computeRoutes",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": routesApiKey.value(),
          "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline",
        },
        body: JSON.stringify({
          origin: { location: { latLng: origin } },
          destination: { location: { latLng: destination } },
          travelMode: "DRIVE",
          routingPreference: "TRAFFIC_AWARE",
          languageCode: "th",
          units: "METRIC",
        }),
      },
    );

    if (!response.ok) {
      const errorBody = await response.text();
      console.error("Routes API failed", response.status, errorBody);
      throw new HttpsError(
        "failed-precondition",
        `Routes API ตอบกลับ ${response.status} ตรวจสอบ API key และการเปิด Routes API`,
      );
    }

    const payload = await response.json() as {
      routes?: Array<{
        duration?: string;
        distanceMeters?: number;
        polyline?: { encodedPolyline?: string };
      }>;
    };
    const route = payload.routes?.[0];
    const encodedPolyline = route?.polyline?.encodedPolyline;
    if (!route || typeof route.distanceMeters !== "number" || !encodedPolyline) {
      throw new HttpsError("not-found", "No route was found for these locations.");
    }

    return {
      encodedPolyline,
      distanceMeters: route.distanceMeters,
      durationSeconds: durationToSeconds(route.duration),
    };
  },
);
