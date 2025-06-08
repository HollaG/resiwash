//firebase-config.js

import { initializeApp, cert, ServiceAccount} from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";


import serviceAccount from "../../service-account.json" 
// Firebase
const app = initializeApp({
  credential: cert(serviceAccount as ServiceAccount),
});

const auth = getAuth(app);
export default auth;
