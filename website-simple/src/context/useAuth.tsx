import { createContext, useContext, useState, useEffect } from "react";
import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  UserCredential,
} from "firebase/auth";



type User = {
  uid: string;
  email: string | null;
  displayName?: string | null;
  photoURL?: string | null;
}
type AuthContextType = {
  currentUser: User | null,
  login: (email: string, password: string) => Promise<UserCredential>;
  register: (email: string, password: string) => Promise<UserCredential>;
  logout: () => Promise<void>;
}

const defaultValue: AuthContextType = {
  currentUser: null,
  login: async (_email: string, _password: string) => {
    throw new Error("login function not implemented");
  },
  register: async (_email: string, _password: string) => {
    throw new Error("register function not implemented");
  },
  logout: async () => {
    throw new Error("logout function not implemented");
  },
}

const AuthContext = createContext<AuthContextType>(defaultValue);

export function useAuth() {
  return useContext(AuthContext);
}

import { ReactNode } from "react";
import auth from "../core/firebase";



export function AuthProvider({ children }: { children: ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // unused
  function register(email: string, password: string) {
    return createUserWithEmailAndPassword(auth, email, password);
  }

  function login(email: string, password: string) {
    return signInWithEmailAndPassword(auth, email, password);
  }

  function logout() {
    return signOut(auth);
}

  useEffect(() => {
    const unsubscribe = auth.onAuthStateChanged((user) => {
      setCurrentUser(user);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value = {
    currentUser,
    login,
    register,
    logout
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
}