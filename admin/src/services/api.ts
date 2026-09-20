import axiosInstance, { setSession, ADMIN_USER_KEY } from 'src/utils/axios';

// ----------------------------------------------------------------------

export type AdminUser = {
  id: string;
  _id?: string;
  email: string;
  full_name: string;
  role: string;
  status: string;
  last_login?: string | null;
  created_at?: string;
};

export type LocationData = {
  state?: string;
  district?: string;
  taluk?: string;
  village?: string;
  latitude?: number | null;
  longitude?: number | null;
};

export type LandSizeData = {
  size_value?: number;
  unit?: string;
};

export type WaterData = {
  sources?: string[];
};

export type CropData = {
  crops?: string[];
  additional_notes?: string;
};

export type DigitalTwin = {
  location?: LocationData;
  land_size?: LandSizeData;
  water?: WaterData;
  crops?: CropData;
};

export type Farmer = {
  id: string;
  _id?: string;
  full_name: string;
  email: string;
  phone_number?: string;
  provider?: string;
  preferred_language?: string;
  profile_completed: boolean;
  status: string;
  last_login?: string | null;
  created_at: string;
  updated_at?: string;
  digital_twin?: DigitalTwin;
};

export type AnalyticsOverview = {
  summary: {
    total_farmers: number;
    active_farmers: number;
    banned_farmers: number;
    completed_profiles: number;
    completion_rate: number;
    total_land_acres: number;
  };
  top_crops: Array<{ label: string; value: number }>;
  top_districts: Array<{ label: string; value: number }>;
  water_sources: Array<{ label: string; value: number }>;
  recent_farmers: Array<{
    id: string;
    full_name: string;
    email: string;
    phone_number?: string;
    status: string;
    profile_completed: boolean;
    created_at?: string;
    state?: string;
    district?: string;
    crops?: string[];
  }>;
};

// ----------------------------------------------------------------------
// Auth Service
// ----------------------------------------------------------------------

export const authService = {
  login: async (email: string, password: string) => {
    const response = await axiosInstance.post('/admin/auth/login', { email, password });
    const { access_token, refresh_token } = response.data;
    setSession(access_token, refresh_token);

    // Fetch admin profile
    const userRes = await axiosInstance.get('/admin/auth/me');
    const userData: AdminUser = userRes.data;
    localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(userData));

    return { tokens: response.data, user: userData };
  },

  getMe: async (): Promise<AdminUser> => {
    const response = await axiosInstance.get('/admin/auth/me');
    const user = response.data;
    localStorage.setItem(ADMIN_USER_KEY, JSON.stringify(user));
    return user;
  },

  logout: () => {
    setSession(null, null);
    localStorage.removeItem(ADMIN_USER_KEY);
  },
};

// ----------------------------------------------------------------------
// Analytics Service
// ----------------------------------------------------------------------

export const analyticsService = {
  getOverview: async (): Promise<AnalyticsOverview> => {
    const response = await axiosInstance.get('/admin/analytics/overview');
    return response.data;
  },
};

// ----------------------------------------------------------------------
// Farmer / User Service
// ----------------------------------------------------------------------

export const farmerService = {
  getFarmers: async (params?: {
    page?: number;
    limit?: number;
    search?: string;
    status_filter?: string;
  }) => {
    const response = await axiosInstance.get('/admin/users', { params });
    return response.data;
  },

  getFarmerById: async (userId: string): Promise<Farmer> => {
    const response = await axiosInstance.get(`/admin/users/${userId}`);
    return response.data;
  },

  updateStatus: async (userId: string, status: 'active' | 'banned') => {
    const response = await axiosInstance.patch(`/admin/users/${userId}/status`, null, {
      params: { status },
    });
    return response.data;
  },

  deleteFarmer: async (userId: string) => {
    const response = await axiosInstance.delete(`/admin/users/${userId}`);
    return response.data;
  },
};

// ----------------------------------------------------------------------
// Admin Management Service
// ----------------------------------------------------------------------

export const adminManagementService = {
  getAdmins: async (params?: { page?: number; limit?: number }) => {
    const response = await axiosInstance.get('/admin/admins', { params });
    return response.data;
  },

  createAdmin: async (data: { full_name: string; email: string; password: string; role: string }) => {
    const response = await axiosInstance.post('/admin/admins', data);
    return response.data;
  },

  updateStatus: async (adminId: string, status: 'active' | 'inactive') => {
    const response = await axiosInstance.patch(`/admin/admins/${adminId}/status`, { status });
    return response.data;
  },

  deleteAdmin: async (adminId: string) => {
    const response = await axiosInstance.delete(`/admin/admins/${adminId}`);
    return response.data;
  },
};

// ----------------------------------------------------------------------
// Knowledge Base Service
// ----------------------------------------------------------------------

export type CollectionInfo = {
  name: string;
  vectors_count: number;
  points_count: number;
  status: string;
};

export type DocumentSummary = {
  document_id: string;
  document_title: string;
  source_file: string;
  category: string;
  language: string;
  region: string;
  crops: string[];
  tags: string[];
  created_at: string;
  chunks_count: number;
};

export type DocumentListResponse = {
  documents: DocumentSummary[];
  total_documents: number;
  total_chunks: number;
};

export type ChunkDetail = {
  chunk_id: string;
  chunk_index: number;
  section_heading: string;
  content: string;
};

export type DocumentDetail = DocumentSummary & {
  chunks: ChunkDetail[];
};

export type SearchResultItem = {
  content: string;
  score: number;
  document_title: string;
  section_heading: string;
  category: string;
  source_file: string;
};

export type SearchResponse = {
  query: string;
  results: SearchResultItem[];
  total: number;
};

export const knowledgeService = {
  getInfo: async (): Promise<CollectionInfo> => {
    const response = await axiosInstance.get('/admin/knowledge/info');
    return response.data;
  },

  getDocuments: async (): Promise<DocumentListResponse> => {
    const response = await axiosInstance.get('/admin/knowledge/documents');
    return response.data;
  },

  getDocumentById: async (documentId: string): Promise<DocumentDetail> => {
    const response = await axiosInstance.get(`/admin/knowledge/documents/${documentId}`);
    return response.data;
  },

  ingestText: async (data: {
    title: string;
    content: string;
    category?: string;
    language?: string;
    region?: string;
    tags?: string[];
    crops?: string[];
  }) => {
    const response = await axiosInstance.post('/admin/knowledge/ingest/text', data);
    return response.data;
  },

  ingestFile: async (formData: FormData) => {
    const response = await axiosInstance.post('/admin/knowledge/ingest/file', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  deleteDocument: async (documentId: string) => {
    const response = await axiosInstance.delete(`/admin/knowledge/documents/${documentId}`);
    return response.data;
  },

  search: async (params: { query: string; category?: string; top_k?: number }): Promise<SearchResponse> => {
    const response = await axiosInstance.post('/admin/knowledge/search', params);
    return response.data;
  },
};

